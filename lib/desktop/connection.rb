#

class Connection
  attr_accessor :last_buf,
                :wslay_callbacks,
                :ws,
                :phr,
                :processing_handshake,
                :ss,
                :socket,
                :ident,
                :server

  def initialize(server, ident, required_prefix)
    self.socket = server.block_accept

    self.server = server
    
    self.ident = ident

    self.ss = ""
    self.last_buf = ""
    self.processing_handshake = true

    self.phr = Phr.new

    @required_prefix = required_prefix

    @closing = false
    @closed = false
  end

  def shutdown
    if @ps
      @ps.kill(UV::Signal::SIGINT)
      @ps.close
      @ps = nil

      @stdin_tty = nil
      @stdout_tty = nil
      @stderr_tty = nil
    end

    if @t
      @t.stop
      @t = nil
    end

    if @fsev
      @fsev.stop
      @fsev = nil
    end
  end

  def halt!
    @halting = true
    self.socket.close
    self.socket = nil
  end

  def serve_static_file!(filename)
    fd = UV::FS::open(filename, UV::FS::O_RDONLY, 0) #, UV::FS::S_IREAD)
    file_size =  fd.stat.size
    sent = 0

    file_type_guess = filename.split(".").last

    content_type = case file_type_guess
      when "wasm"
        "Content-Type: application/wasm\r\n"
      when "js"
        "Content-Type: text/javascript\r\n"
      when "css"
        "Content-Type: text/css\r\n"
      when "html"
        "Content-Type: text/html\r\n"
      when "txt"
        "Content-Type: text/plain\r\n"
      else
        ""
      end

    header = "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Length: #{file_size}\r\nTransfer-Coding: chunked\r\n#{content_type}\r\n"
    #header = "HTTP/1.1 200 OK\r\nContent-Length: #{file_size}\r\n#{content_type}\r\n"
    self.socket.write(header) {
      max_chunk = 10240 #(self.socket.recv_buffer_size / 2).to_i
      sending = false

      send_proc = Proc.new {
        if (sent < file_size)
          left = file_size - sent
          if left > max_chunk
            left = max_chunk
          end

          wkread = fd.read(left, sent)
          self.socket.write(wkread) { |foo|
            if foo.is_a?(UVError)
              send_proc.call
            else
              sent += wkread.length

              if (sent < file_size)
                begin
                  send_proc.call
                rescue => e
                  log!(:eee, e)
                end
              else
                fd.close
                fd = nil

                self.socket.read_stop
                self.socket.close
                self.socket = nil
              end
            end
          }
        else
          fd.close
          fd = nil

          self.socket.read_stop
          self.socket.close
          self.socket = nil

          #idle.stop
          self.processing_handshake = true
        end
      }
      #end

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
        case phr.path
        when "/status"
          self.socket && self.socket.write("HTTP/1.1 200 OK\r\nConnection: Close\r\nContent-Length: 0\r\n\r\n") {
            self.halt!
          }

        #when "/debug"
        #  serve_static_file!("/var/tmp/big.data")

        when "/ws"
          upgrade_to_websocket!

        else
          unless @required_prefix
            response_bytes = server.missing_response
            self.socket && self.socket.write(response_bytes) {
              self.halt!
            }
          else
            filename = phr.path

            do_upstream_handling = Proc.new {
              response_bytes = server.match_dispatch(filename)

              self.socket && response_bytes && self.socket.write(response_bytes) {
                self.halt!
              }
            }

            if filename == "/" #|| filename[0, 2] == "/~"
              do_upstream_handling.call
            else
              #  filename = "/index.html"
              #end
              requested_path = "#{@required_prefix}#{filename}"
              UV::FS.realpath(requested_path) { |resolved_filename|
                if resolved_filename.is_a?(UVError) || !resolved_filename.start_with?(@required_prefix)
                  do_upstream_handling.call
                else
                  self.processing_handshake = -1
                  self.ss = self.ss[@offset..-1]
                  #self.phr.reset
                  serve_static_file!(resolved_filename)
                end
              }
            end
          end
        end
      when :incomplete
        log!("desktop_connection_incomplete")
      when :parser_error
        log!(:desktop_connection_parser_error, @offset)
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
      self.shutdown
    else
      if b && b.is_a?(String)
        self.handle_bytes!(b)
      end
    end
  end

  def upgrade_to_websocket!
    self.wslay_callbacks = Wslay::Event::Callbacks.new

    self.wslay_callbacks.recv_callback do |buf, len|
      # when wslay wants to read data
      # buf is a cptr, if your I/O gem can write to a C pointer you have to write at most len bytes into it
      # and return the bytes written
      # or else return a mruby String or a object which can be converted into a String via to_str
      # and be up to len bytes long
      # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when there is nothing to read
      #log!("SDSD", self.last_buf, buf, len, buf.to_s)

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

      if msg[:opcode] == :binary_frame
        process_as_msgpack_stream(msg.msg) { |typed_msg|
          channels = typed_msg.keys

          channels.each do |channel|
            #NOTE: channels are as follows
            #
            #  0 stdin of connected tty
            #  c is stuff from the client
            #  * everything else gets sent to user-defined handler
            case channel
              when 0
                @stdin_tty && @stdin_tty.write(typed_msg[channel]) {
                  false
                }

              when 3
                if @ftty
                  FastTTY.resize(@ftty[0], typed_msg[channel][0], typed_msg[channel][1])
                else
                  @pending_resize = typed_msg[channel]
                end

              when "party"
                wkndrfile_req = typed_msg[channel]
                self.server.subscribe_to_wkndrfile(wkndrfile_req, self)

              when "c"
                dispatch_req = typed_msg[channel]
                if dispatch_req == "tty"
                  unless @ps
                    @ftty = FastTTY.fd

                    @stdin_tty = UV::Pipe.new(false)
                    @stdin_tty.open(@ftty[0])

                    @stdout_tty = UV::Pipe.new(false)
                    @stdout_tty.open(@ftty[1])

                    @pid = @ftty[2].gsub("/dev/", "")

                    @ps = UV::Process.new({
                      'stdio' => [@ftty[1], @ftty[1], @ftty[1]],
                      #'file' => '/usr/bin/ruby',
                      #'args' => ['/var/lib/wkndr/Thorfile', 'getty', @pid],
                      'file' => '/sbin/agetty',
                      'args' => ["--timeout", "30", "--login-program", "/usr/bin/ruby", "--login-options", "/var/lib/wkndr/exgetty.rb login -- \\u", "115200", @pid, "xterm-256color"],
                      'detached' => true,
                      'env' => []
                    })

                    if @pending_resize
                      FastTTY.resize(@ftty[0], @pending_resize[0], @pending_resize[1])
                      @pending_resize = nil
                    end

                    @ps.spawn do |sig|
                      log!(:ps_spawn_exit, "exitsig #{sig}")

                      @pid = nil
                      @ps = nil
                    end

                    @stdin_tty.read_start do |bout|
                      if bout.is_a?(UVError)
                        log!(:badout, bout)
                      elsif bout
                        outbits = {1 => bout}
                        self.write_typed(outbits)
                      end
                    end
                    
                    @ps.kill(0)
                  else
                    log!(:ps_exists, @ps)
                    @ps.kill(0)
                  end
                end
            end
          end
        }
      end
    end

    self.wslay_callbacks.send_callback do |buf|
      # when there is data to send, you have to return the bytes send here
      # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when sending would block

      if self.socket && !@halted
        self.socket.try_write(buf)
      else
        0
      end
    end

    self.ws = Wslay::Event::Context::Server.new self.wslay_callbacks

    #TODO??? !!! !!!! !!!!
    #unless WebSocket.create_accept(key).securecmp(phr.headers.to_h.fetch('sec-websocket-accept'))
    #   raise Error, "Handshake failure"
    #end

    sec_websocket_key = self.phr.headers.detect { |k,v|
      k == "sec-websocket-key"
    }[1]

    #NOTE: this is the server to client side
    self.write_ws_response!(sec_websocket_key) {
      @t = UV::Timer.new
      @t.start(100, 100) {
        self.write_typed({"c" => "ping"})
      }
    }

    self.processing_handshake = false
    self.last_buf = self.ss[@offset..-1] #TODO: rescope offset
    proto_ok = (self.ws.recv != :proto)
    unless proto_ok
      log!(:wss_handshake_error)
      self.halt!
    end
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
      log!(:server_out_err, e)

      self.halt!
      self.shutdown
    end
  end
end
