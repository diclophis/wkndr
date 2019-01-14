#

def Integer(f)
  f.to_i
end

##TODO: move this somewhere
$stdout = UV::Pipe.new
$stdout.open(1)
$stdout.read_stop

def log!(*args, &block)
  $stdout.write(args.inspect + "\n") {
    yield if block
  }
end

class Connection
  attr_accessor :last_buf,
                :wslay_callbacks,
                :ws,
                :phr,
                :processing_handshake,
                :ss,
                :socket

  def initialize(socket, required_prefix)
    self.socket = socket

    self.ss = ""
    self.last_buf = ""
    self.processing_handshake = true

    self.phr = Phr.new

    @required_prefix = required_prefix

    @closing = false
    @closed = false
  end

  def disconnect!
    if @ps
      @ps.kill(UV::Signal::SIGINT)
      @ps.close
      @ps = nil

      @stdin_tty.close
      @stdout_tty.close
      @stderr_tty.close

      @stderr = nil
      @stdout = nil
      @stderr = nil
    end

    if self.socket && self.socket.has_ref?
      self.socket.read_stop 
      self.socket.close
      self.socket = nil
    end
  end

  def halt!
    @halting = true
  end

  def serve_static_file!(filename)
    #TODO: close opened files
    fd = UV::FS::open(filename, UV::FS::O_RDONLY, UV::FS::S_IREAD)
    file_size =  fd.stat.size
    sent = 0

    header = "HTTP/1.1 200 OK\r\nContent-Length: #{file_size}\r\nTransfer-Coding: chunked\r\n\r\n"
    self.socket.write(header) {
      max_chunk = (self.socket.recv_buffer_size / 4).to_i
      sending = false

      idle = UV::Idle.new
      idle.start do |x|
        if @halting
          idle.stop
        end

        if (sent < file_size)
          left = file_size - sent
          if left > max_chunk
            left = max_chunk
          end

          begin
            if !sending
              bsent = sent
              sending = true
              UV::FS::sendfile(self.socket.fileno, fd, bsent, left) { |xyx|
                if xyx.is_a?(UVError)
                  max_chunk = ((max_chunk / 2) + 1).to_i
                  sending = false
                else
                  sending = false
                  sent += xyx.to_i
                end
              }
            end
          rescue UVError #resource temporarily unavailable
            max_chunk = ((max_chunk / 2) + 1).to_i
            sending = false
          end
        else
          #self.socket.close
          fd.close
          idle.stop
          self.processing_handshake = true
        end
      end
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
        log!(:get, self.object_id, phr.path)

        case phr.path
        when "/debug"
          serve_static_file!("/var/tmp/big.data")

        when "/ws"
          upgrade_to_websocket!

        else
          filename = phr.path

          if filename == "/"
            filename = "/index.html"
          end

          requested_path = "#{@required_prefix}#{filename}"
          UV::FS.realpath(requested_path) { |resolved_filename|
            #log!(self, resolved_filename, requested_path, @required_prefix, ARGV)

            if resolved_filename.is_a?(UVError) || !resolved_filename.start_with?(@required_prefix)
              self.socket.write("HTTP/1.1 404 Not Found\r\nConnection: Close\r\nContent-Length: 0\r\n\r\n") {
                #self.socket.close
                self.halt!
              }
            else
              self.processing_handshake = -1
              self.ss = self.ss[@offset..-1]
              self.phr.reset
              serve_static_file!(resolved_filename)
            end
          }
        end
      when :incomplete
        log!("incomplete")
      when :parser_error
        log!(:parser_error, @offset)
      end
    else
      if self.ws
        self.last_buf = b
        proto_ok = (self.ws.recv != :proto)
        unless proto_ok
          #self.socket.close
          self.halt!
        end
      end
    end
  end

  def write_ws_response!(sec_websocket_key)
    key = WebSocket.create_accept(sec_websocket_key)

    self.socket.write("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: #{key}\r\n\r\n")
  end

  def read_bytes_safely(b)
    if @halting
      #NO
    elsif (b && b.is_a?(UVError))
      self.disconnect!
    else
      if b && b.is_a?(String)
        self.handle_bytes!(b)
      end
    end
  end

  def upgrade_to_websocket!
    #log!(:debug_upgrade)

    @stdin_tty = UV::Pipe.new(false)
    @stdout_tty = UV::Pipe.new(false)
    @stderr_tty = UV::Pipe.new(false)

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
        throw_away_buf = self.last_buf.dup
        self.last_buf = nil
        throw_away_buf
      else
        nil
      end
    end

    #TODO: this is where the ws msgs are recvd
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
        #log!("INBOUND", msg, msg.to_s)

        @stdin_tty.write(msg.msg) {
          false
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

    #TODO??? !!!
    #unless WebSocket.create_accept(key).securecmp(phr.headers.to_h.fetch('sec-websocket-accept'))
    #   raise Error, "Handshake failure"
    #end

    sec_websocket_key = self.phr.headers.detect { |k,v|
      k == "sec-websocket-key"
    }[1]

    #$stdout.write(sec_websocket_key)

    self.write_ws_response!(sec_websocket_key)

    ps = UV::Process.new({
      #'file' => 'factor',
      #'args' => [],
      'file' => 'sh',
      'args' => [],
      #'file' => "/usr/sbin/chroot",
      #'args' => ["/var/tmp/chroot", "/bin/sh"],
      #'args' => ["/var/tmp/chroot", "/bin/vim-static"],
      #'file' => 'nc',
      #'args' => ["localhost", "12345"],
      #'args' => ["towel.blinkenlights.nl", "23"],
      #'file' => 'htop',
      #'args' => ["-d0.1"],
      #TODO: proper env cleanup!!
      'env' => ['TERM=xterm-256color'],
    })

    ps.stdin_pipe = @stdin_tty
    ps.stdout_pipe = @stdout_tty
    ps.stderr_pipe = @stderr_tty

    ps.spawn do |sig|
      log!("exit #{sig}")
    end

    @stderr_tty.read_start do |bbbb|
      if bbbb.is_a?(UVError)
        log!(:baderr, bbbb)
      elsif bbbb && bbbb.length > 0
        self.ws.queue_msg(bbbb, :binary_frame)
        outg = self.ws.send
      end
    end

    @stdout_tty.read_start do |bout|
      if bout.is_a?(UVError)
        log!(:badout, bout)
      elsif bout
        self.ws.queue_msg(bout, :binary_frame)
        outg = self.ws.send
        log!(:outg, outg)
        outg
      end
    end

    #TODO???
    ps.kill(0)

    self.processing_handshake = false
    self.last_buf = self.ss[@offset..-1] #TODO: rescope offset
    proto_ok = (self.ws.recv != :proto)
    unless proto_ok
      log!(:wss_handshake_error)
      #self.socket.close
      self.halt!
    end

    @ps = ps
  end
end

class Server
  def self.run!(directory)
    server = Server.new(directory)
  end

  def initialize(required_prefix)
    #TODO: where does this go????
    UV.disable_stdio_inheritance
    #required_prefix = "/home/jon/workspace/wkndr/public/"
    @required_prefix = required_prefix #"/var/lib/wkndr/public/"
    log!(:wtf, self, @required_prefix)

    host = '0.0.0.0'
    port = 8000
    @address = UV.ip4_addr(host, port)

    @server = UV::TCP.new
    @server.bind(@address)
    @server.listen(1) { |connection_error|
      self.on_connection(connection_error)
    }

    @all_connections = []

    @closing = false
    @closed = false
  end

  def shutdown
    @all_connections.each { |cn|
      cn.disconnect!
    }

    @server.close
  end

  def running
    !@halting
  end

  def halt!
    @halting = @all_connections.all? { |cn| cn.halt! }
  end

  def on_connection(connection_error)
    if connection_error
      log!(connection_error)
    else
      self.create_connection!
    end
  end

  def create_connection!
    http = Connection.new(@server.accept, @required_prefix)

    @all_connections << http

    http.socket.read_start { |b|
      http.read_bytes_safely(b)
    }

    http
  end

  def update
    #NOOP: TODO????
  end

  def socket_klass
    WslaySocketStream
  end

  def create_websocket_connection(&block)
    ss = WslaySocketStream.new(self, block)
    @all_connections << ss
    ss.connect!
    ss
  end
end
