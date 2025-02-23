#

class Connection
  attr_accessor :last_buf,
                :wslay_callbacks,
                :ws,
                :phr,
                :processing_handshake,
                :ss,
                :socket,
                :session,
                :hex

  def initialize(gl, socket)
    @gl = gl

    self.socket = socket

    self.ss = ""
    self.last_buf = ""
    self.processing_handshake = true

    self.phr = Phr.new
    self.session = {}
    self.hex = Sysrandom.random

    @closing = false
    @closed = false
    @pending_requests = []
    @pending_parties = []
    @subscriptions = {}

    self.socket.read_start { |b|
      read_bytes_safely(b)
    }
  end

  def client_to_server(channel, msg)
    @gl.event("main", channel, msg)
  end

  def shutdown
    #if @ps
    #  @ps.kill(UV::Signal::SIGINT)
    #  @ps.close
    #  @ps = nil
    #  @stdin_tty = nil
    #  @stdout_tty = nil
    #  @stderr_tty = nil
    #end

    #if @t
    #  @t.stop
    #  @t = nil
    #end

    #if @fsev
    #  @fsev.stop
    #  @fsev = nil
    #end
    
    #halt!
  end

  def running?
    !@halting
  end

  def halt!
    @halting = true

    if self.socket
      self.socket.close
      self.socket = nil
    end
  end

  def serve_static_file!(filename)
    self.processing_handshake = -1
    self.ss = self.ss[@offset..-1]

    #log!(:wtf, filename)

    fd = UV::FS::open(filename, UV::FS::O_RDONLY, 0)
    file_size =  fd.stat.size
    sent = 0

    header = Protocol.chunked_header(file_size, filename)

    self.socket.write(header) {
      max_chunk = self.socket.send_buffer_size #  / 8 #1 #02400
      sending = false

      send_proc = Proc.new {
        if (sent < file_size)
          left = file_size - sent
          if left > max_chunk
            left = max_chunk
          end

          wkread = fd.read(left, sent)
          #self.socket can be nil!!!!
          return unless self.socket
          self.socket.write(wkread) { |foo|
            if foo.is_a?(UVError)
              send_proc.call
            else
              sent += wkread.length

              if (sent < file_size)
                #begin
                  send_proc.call
                #rescue => e
                  #TODO: !!!!
                #  log!(:eee, e)
                #end
              else
                fd.close
                fd = nil

                if self.socket
                  self.socket.read_stop
                  self.socket.close
                  self.socket = nil
                end
              end
            end
          }
        else
          fd.close
          fd = nil

          self.socket.read_stop
          self.socket.close
          self.socket = nil

          self.processing_handshake = true
        end
      }

      send_proc.call
    }
  end

  def handle_bytes!(b)
    if self.processing_handshake == -1
      self.ss += b
    elsif self.processing_handshake
      self.ss += b
      @offset = self.phr.parse_request(self.ss)
      case @offset
        when Fixnum
          self.enqueue_request(phr)

        when :incomplete
          #TODO: ??? log!("desktop_connection_incomplete")

        when :parser_error
          #log!(:desktop_connection_parser_error, @offset)
          #TODO: better halting ???

      end
    else
      if self.ws
        self.last_buf += b
        proto_ok = (self.ws.recv != :proto)
        unless proto_ok
          self.halt!
        end
      end
    end
  end

  def enqueue_request(request)
    @pending_requests << request
  end

  def has_pending_request?
    running? && (@pending_requests.count > 0)
  end

  def pop_request!
    @pending_requests.pop
  end

  def has_pending_parties?
    running? && (@pending_parties.count > 0)
  end

  def pop_party!
    @pending_parties.pop
  end

  def write_response(response_bytes)
    self.socket && response_bytes && self.socket.write(response_bytes) { |*a|
      #log!(:WWEWEWEWE, a)
      self.halt!
    }
  end

  def pid
    @pid
  end

  #TODO: include module maybe?????
  def process_as_msgpack_stream(bytes)
    all_bits_to_consider = (@left_over_bits || "") + bytes
    all_l = all_bits_to_consider.length

    unpacked_length = MessagePack.unpack(all_bits_to_consider) do |result|
      yield result if result
    end

    @left_over_bits = all_bits_to_consider[unpacked_length, all_l]
  end

  def write_ws_response!(sec_websocket_key)
    key = WebSocket.create_accept(sec_websocket_key)

    self.socket.write("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: #{key}\r\n\r\n") {
      yield
    }
  end

  def read_bytes_safely(b)
    if @halting
      #NO
    elsif (b && b.is_a?(UVError))
      self.halt!
      self.shutdown
    else
      if b && b.is_a?(String)
        self.handle_bytes!(b)
      end
    end
  end

  def upgrade_to_websocket!(&block)
    self.wslay_callbacks = Wslay::Event::Callbacks.new

    self.wslay_callbacks.recv_callback do |buf, len|
      # when wslay wants to read data
      # buf is a cptr, if your I/O gem can write to a C pointer you have to write at most len bytes into it
      # and return the bytes written
      # or else return a mruby String or a object which can be converted into a String via to_str
      # and be up to len bytes long
      # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when there is nothing to read
      # log!("SDSD", self.last_buf, buf, len, buf.to_s)

      if self.last_buf
        self.last_buf.slice!(0, len)
      else
        nil
      end
    end

    self.wslay_callbacks.on_msg_recv_callback do |msg|
      # when a WebSocket msg is fully recieved this callback is called
      # you get a Wslay::Event::OnMsgRecvArg Struct back with the following fields
      # :rsv => reserved field from WebSocket spec, there are Wslay.get_rsv1/2/3 helper methods
      # :opcode => :continuation_frame, :text_frame, :binary_frame, :connection_close, :ping or
      # :pong, Wslay.is_ctrl_frame? helper method is provided too
      # :msg => the message revieced
      # :status_code => :normal_closure, :going_away, :protocol_error, :unsupported_data, :no_status_rcvd,
      # :abnormal_closure, :invalid_frame_payload_data, :policy_violation, :message_too_big, :mandatory_ext,
      # :internal_server_error, :tls_handshake
      # to_str => returns the message revieced

      if msg[:opcode] == :connection_close
        self.halt!
        self.shutdown
      elsif msg[:opcode] == :binary_frame
        process_as_msgpack_stream(msg.msg) { |typed_msg|
          #Wkndr.log! [:wtf, self, typed_msg]

          channels = typed_msg.keys

#TODO: is this server side only??????????

          channels.each do |channel|
#          log!(channel, typed_msg)

            #NOTE: channels are as follows
            #
            #  0 stdin of connected tty
            #  c is stuff from the client
            #  * everything else gets sent to user-defined handler
            case channel
              #when 0
              #  @stdin_tty && @stdin_tty.write(typed_msg[channel]) {
              #    false
              #  }
              #TODO: this calles into kiloOnInputReceived
  
              #when 1 #mrb_funcall(mrb, mrb_obj_value(selfP), "write_typed", 1, outbound_tty_msg);

              #TODO: js calls into TTY interface for resize
              #when 3
              #  if @ftty
              #    FastTTY.resize(@ftty[0], typed_msg[channel][0], typed_msg[channel][1])
              #  else
              #    @pending_resize = typed_msg[channel]
              #  end

              #TODO: what is this loop for???
              when "party" #TODO: rename this something not stupid
                wkndrfile_req = typed_msg[channel]

                if wkndrfile_req == "/"
                  wkndrfile_req = "Wkndrfile" #TODO: ?????
                end

                #log!(:client_wants, wkndrfile_req)

                @pending_parties << wkndrfile_req

              else
                block.call(self, channel, typed_msg[channel]) if block

            end
          end
        }

      elsif msg[:opcode] == :text_frame
        block.call(self, msg.msg) if block
      else
        log!(:UNKNOWN_OPCODE, msg[:opcode])
      end
    end

    self.wslay_callbacks.send_callback do |buf|
      # when there is data to send, you have to return the bytes send here
      # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when sending would block

      if self.socket && !@halted
        self.socket && buf && self.socket.write(buf) {
          #self.halt!
          #TODO: ???
        }
        buf.length
      else
        0
      end
    end

    self.ws = Wslay::Event::Context::Server.new self.wslay_callbacks
    #log!(:SETWSWSWSWSWS, self.ws, self)

    sec_websocket_key = self.phr.headers.detect { |k,v|
      k == "sec-websocket-key"
    }[1]

    #TODO: !!! lib/desktop/connection.rb:321:in upgrade_to_websocket!: undefined method '[]' (NoMethodError)

    #NOTE: this is the server to client side
    abc = self.write_ws_response!(sec_websocket_key) {
      #TODO: ???
      #@t = UV::Timer.new
      #@t.start(100, 100) {
      #  self.write_typed({"c" => "ping"})
      #  #self.write_text("ping")
      #}
    }

    self.processing_handshake = false
    self.last_buf = self.ss[@offset..-1] #TODO: rescope offset
    proto_ok = (self.ws.recv != :proto)
    unless proto_ok
      #log!(:wss_handshake_error)
      #TODO: better halting
      self.halt!
    end

    return abc
  end

  #TODO: merge this with class with SocketStream
  def write_typed(*msg_typed)
    begin
      if self.ws
        msg = MessagePack.pack(*msg_typed)
        self.ws.queue_msg(msg, :binary_frame)
        outg = self.ws.send
        outg
      end
    rescue Wslay::Err => e
      #log!(:connection_out_err, e)

      self.halt!
      self.shutdown
    end
  end

  def write_text(txt)
    begin
      if self.ws
        self.ws.queue_msg(txt, :text_frame)
        outg = self.ws.send
        outg
      end
    rescue Wslay::Err => e
      log!(:connection_out_err, e)

      self.halt!
      self.shutdown
    end
  end

  def subscribed_to?(path)
    if running?
      @subscriptions[path]
    end
  end

  def add_subscription!(path, phr)
    @subscriptions[path] = phr
  end

  def get_subscriptions
    @subscriptions
  end
end
