#

def Integer(f)
  f.to_i
end

$stdout = UV::Pipe.new
$stdout.open(1)
$stdout.read_stop

def log!(*args)
  $stdout.write(args.inspect + "\n") {
    false
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

  def initialize(socket)
    self.socket = socket

    self.ss = ""
    self.last_buf = ""
    self.processing_handshake = true

    self.phr = Phr.new
  end

  def disconnect!
    self.socket.unref if self.socket
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
          self.socket.close
          idle.stop
        end
      end
    }
  end

  def handle_bytes!(b)
    if self.processing_handshake
      self.ss += b
      @offset = self.phr.parse_request(self.ss)
      case @offset
      when Fixnum
        log!(:get, phr.path)

        case phr.path
        when "/debug"
          serve_static_file!("/var/tmp/big.data")

        when "/wss"
          upgrade_to_websocket!

        else
          filename = phr.path
          log!(phr.path)

          if filename == "/"
            filename = "/index.html"
          end

          #required_prefix = "/home/jon/workspace/kit1zx/server/"
          required_prefix = "/var/tmp/kit1zx/server/"

          UV::FS.realpath("#{required_prefix}#{filename}") { |resolved_filename|
            if resolved_filename.is_a?(UVError) || !resolved_filename.start_with?(required_prefix)
              self.socket.write("HTTP/1.1 404 Not Found\r\nConnection: Close\r\nContent-Length: 0\r\n\r\n") {
                self.socket.close
              }
            else
              serve_static_file!(resolved_filename)
            end
          }
        end
      when :incomplete
        log!("incomplete")
      when :parser_error
        log!(:parser_error, offset)
      end
    else
      if self.ws
        self.last_buf = b
        proto_ok = (self.ws.recv != :proto)
        unless proto_ok
          self.socket.close
        end
      end
    end
  end

  def write_ws_response!(sec_websocket_key)
    key = WebSocket.create_accept(sec_websocket_key)

    self.socket.write("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: #{key}\r\n\r\n")
  end

  def read_bytes_safely(b)
    if b && b.is_a?(UVError)
      self.disconnect!
    else
      if b && b.is_a?(String)
        self.handle_bytes!(b)
      end
    end
  end

  def upgrade_to_websocket!
    stdin_tty = UV::Pipe.new(false)
    stdout_tty = UV::Pipe.new(false)
    stderr_tty = UV::Pipe.new(false)

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
        #log!("INBOUND", msg)

        stdin_tty.write(msg) {
          false
        }
      end
    end

    self.wslay_callbacks.send_callback do |buf|
      # when there is data to send, you have to return the bytes send here
      # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when sending would block
      self.socket.try_write(buf)
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
      #'file' => 'sh',
      #'args' => [],
      'file' => "/usr/sbin/chroot",
      'args' => ["/var/tmp/chroot", "/bin/sh"],
      #'args' => ["/var/tmp/chroot", "/bin/vim-static"],
      #'file' => 'nc',
      #'args' => ["localhost", "12345"],
      #'args' => ["towel.blinkenlights.nl", "23"],
      #'file' => 'htop',
      #'args' => ["-d0.1"],
      #TODO: proper env cleanup!!
      'env' => ['TERM=xterm-256color'],
    })

    ps.stdin_pipe = stdin_tty
    ps.stdout_pipe = stdout_tty
    ps.stderr_pipe = stderr_tty

    ps.spawn do |sig|
      log!("exit #{sig}")
    end

    stderr_tty.read_start do |bbbb|
      if bbbb.is_a?(UVError)
        log!(:baderr, bbbb)
      elsif bbbb && bbbb.length > 0
        self.ws.queue_msg(bbbb, :binary_frame)
        outg = self.ws.send
      end
    end

    stdout_tty.read_start do |bout|
      if bout.is_a?(UVError)
        log!(:badout, bout)
      elsif bout
        self.ws.queue_msg(bout, :binary_frame)
        outg = self.ws.send
      end
    end

    #TODO???
    #@ps.kill(0)

    self.processing_handshake = false
    self.last_buf = self.ss[@offset..-1] #TODO: rescope offset
    proto_ok = (self.ws.recv != :proto)
    unless proto_ok
      log!(:wss_handshake_error)
      self.socket.close
    end
  end
end

class Server
  def initialize
    host = '0.0.0.0'
    port = 8000
    @address = UV.ip4_addr(host, port)

    @server = UV::TCP.new
    @server.bind(@address)
    @server.listen(1) { |connection_error|
      self.on_connection(connection_error)
    }
  end

  def on_connection(connection_error)
    if connection_error
      log!(connection_error)
    else
      self.create_connection!
    end
  end

  def create_connection!
    http = Connection.new(@server.accept)

    http.socket.read_start { |b|
      http.read_bytes_safely(b)
    }

    http
  end

  def spinlock!
    UV.disable_stdio_inheritance
    UV::run
  end
end

server = Server.new
server.spinlock!
