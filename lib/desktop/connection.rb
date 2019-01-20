#

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

  def shutdown
    log!(:connection_shutdown)

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

    if @t
      @t.stop
      @t = nil
    end

    if @fsev
      @fsev.stop
      @fsev = nil
    end

    if self.socket && self.socket.has_ref?
      self.socket.read_stop 
      self.socket.close
      self.socket = nil
    end
  end

  def halt!
    log!(:halt_connection)

    @halting = true
  end

  def serve_static_file!(filename)
    fd = UV::FS::open(filename, UV::FS::O_RDONLY, UV::FS::S_IREAD)
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
      else
        ""
      end

    header = "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Length: #{file_size}\r\nTransfer-Coding: chunked\r\n#{content_type}\r\n"
    self.socket.write(header) {
      max_chunk = (self.socket.recv_buffer_size / 2).to_i
      sending = false

      idle = UV::Timer.new #deadlocks??? UV::Idle.new
      idle.start(0, 16) do |x|
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
          filename = phr.path

          if filename == "/"
            filename = "/index.html"
          end

          requested_path = "#{@required_prefix}#{filename}"
          UV::FS.realpath(requested_path) { |resolved_filename|
            #log!(resolved_filename, @required_prefix)

            if resolved_filename.is_a?(UVError) || !resolved_filename.start_with?(@required_prefix)
              self.socket && self.socket.write("HTTP/1.1 404 Not Found\r\nConnection: Close\r\nContent-Length: 0\r\n\r\n") {
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
        self.last_buf += b
        proto_ok = (self.ws.recv != :proto)
        unless proto_ok
          #self.socket.close
          self.halt!
        end
      end
    end
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
    @stdin_tty = UV::Pipe.new(false)
    #stdin_tty = UV::Pipe.new(false)


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
            case channel
              when 0
                @stdin_tty.write(typed_msg[channel]) {
                  false
                }
            else
              log!("INBOUND", typed_msg)
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

    #TODO??? !!!
    #unless WebSocket.create_accept(key).securecmp(phr.headers.to_h.fetch('sec-websocket-accept'))
    #   raise Error, "Handshake failure"
    #end

    sec_websocket_key = self.phr.headers.detect { |k,v|
      k == "sec-websocket-key"
    }[1]

    self.write_ws_response!(sec_websocket_key) {

      write_wkndr_file = Proc.new {
        ffff = UV::FS::open("/var/tmp/chroot/Wkndrfile", UV::FS::O_RDONLY, 0)
        wkread = ffff.read
        self.write_typed({"p" => wkread})
        ffff.close

        @fsev = UV::FS::Event.new
        @fsev.start("/var/tmp/chroot/Wkndrfile", 0) do |path, event|
          log!(:fswatch, path, event)

          if event == :change
            @fsev.stop

            write_wkndr_file.call
          end
        end
      }

      write_wkndr_file.call

      @t = UV::Timer.new
      @t.start(1000, 1000) {
        self.write_typed({"c" => "ping"})
      }

      @ps = UV::Process.new({
        #'file' => 'factor',
        #'args' => [],
        #'file' => 'sh',
        #'args' => [],
        'file' => "/usr/sbin/chroot",
        'args' => ["/var/tmp/chroot", "/bin/bash", "-i", "-l"],
        #'args' => ["/var/tmp/chroot", "/bin/vi", "Wkndrfile"],
        #'file' => 'nc',
        #'args' => ["localhost", "12345"],
        #'args' => ["towel.blinkenlights.nl", "23"],
        #'file' => 'htop',
        #'args' => ["-d0.1"],
        #TODO: proper env cleanup!!
        'env' => [
          'TERM=xterm-256color',
          'VIMRUNTIME=/usr/share/vim',
          'LS_COLORS=rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:',
          'LANG=en_US.UTF-8',
          'TERMCAP=SC|screen|VT 100/ANSI X3.64 virtual terminal:\ :DO=\E[%dB:LE=\E[%dD:RI=\E[%dC:UP=\E[%dA:bs:bt=\E[Z:\ :cd=\E[J:ce=\E[K:cl=\E[H\E[J:cm=\E[%i%d;%dH:ct=\E[3g:\ :do=^J:nd=\E[C:pt:rc=\E8:rs=\Ec:sc=\E7:st=\EH:up=\EM:\ :le=^H:bl=^G:cr=^M:it#8:ho=\E[H:nw=\EE:ta=^I:is=\E)0:\ :li#45:co#182:am:xn:xv:LP:sr=\EM:al=\E[L:AL=\E[%dL:\ :cs=\E[%i%d;%dr:dl=\E[M:DL=\E[%dM:dc=\E[P:DC=\E[%dP:\ :im=\E[4h:ei=\E[4l:mi:IC=\E[%d@:ks=\E[?1h\E=:\ :ke=\E[?1l\E>:vi=\E[?25l:ve=\E[34h\E[?25h:vs=\E[34l:\ :ti=\E[?1049h:te=\E[?1049l:us=\E[4m:ue=\E[24m:so=\E[3m:\ :se=\E[23m:mb=\E[5m:md=\E[1m:mh=\E[2m:mr=\E[7m:\ :me=\E[m:ms:\ :Co#8:pa#64:AF=\E[3%dm:AB=\E[4%dm:op=\E[39;49m:AX:\ :vb=\Eg:G0:as=\E(0:ae=\E(B:\ :ac=\140\140aaffggjjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~..--++,,hhII00:\ :po=\E[5i:pf=\E[4i:Km=\E[M:k0=\E[10~:k1=\EOP:k2=\EOQ:\ :k3=\EOR:k4=\EOS:k5=\E[15~:k6=\E[17~:k7=\E[18~:\ :k8=\E[19~:k9=\E[20~:k;=\E[21~:F1=\E[23~:F2=\E[24~:\ :F3=\E[1;2P:F4=\E[1;2Q:F5=\E[1;2R:F6=\E[1;2S:\ :F7=\E[15;2~:F8=\E[17;2~:F9=\E[18;2~:FA=\E[19;2~:\ :FB=\E[20;2~:FC=\E[21;2~:FD=\E[23;2~:FE=\E[24;2~:kb=:\ :K2=\EOE:kB=\E[Z:kF=\E[1;2B:kR=\E[1;2A:*4=\E[3;2~:\ :*7=\E[1;2F:#2=\E[1;2H:#3=\E[2;2~:#4=\E[1;2D:%c=\E[6;2~:\ :%e=\E[5;2~:%i=\E[1;2C:kh=\E[1~:@1=\E[1~:kH=\E[4~:\ :@7=\E[4~:kN=\E[6~:kP=\E[5~:kI=\E[2~:kD=\E[3~:ku=\EOA:\ :kd=\EOB:kr=\EOC:kl=\EOD:km:',
        ]
      })

      @ps.stdin_pipe = @stdin_tty
      @ps.stdout_pipe = @stdout_tty
      @ps.stderr_pipe = @stderr_tty

      @ps.spawn do |sig|
        log!("exit #{sig}")
      end

      @stderr_tty.read_start do |bbbb|
        if bbbb.is_a?(UVError)
          log!(:baderr, bbbb)
        elsif bbbb && bbbb.length > 0
          self.write_typed({2 => bbbb})
        end
      end

      @stdout_tty.read_start do |bout|
        if bout.is_a?(UVError)
          log!(:badout, bout)
        elsif bout
          outbits = {1 => bout}
          self.write_typed(outbits)
        end
      end

      #TODO???
      @ps.kill(0)

      #@stdin_tty = UV::TTY.new(0, 1)
      #@stdin_tty.open(stdin_tty.fileno)
      #@stdin_tty.set_mode(0)
      #@stdin_tty.reset_mode
      #win = @stdin_tty.get_winsize
      #a_tty = UV::TTY.new(0, 1)
      #a_tty.open(@stdin_tty.fileno)
      #(a_tty.fileno)
      #log!(:WINSIZE, win)
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
