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
    self.socket = server.block

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

    #if self.socket && self.socket.has_ref?
    #  self.socket.read_stop 
    #  self.socket.close
    #  self.socket = nil
    #end
  end

  def halt!
    @halting = true
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

      #idle = UV::Timer.new #deadlocks??? UV::Idle.new
      #idle.start(0, 1000) do |x|
      #idle = UV::Idle.new
      #idle.start do |x|
        #log!(:server_idle, self, self.socket)
        #if @halting
        #  idle.stop
        #end

      send_proc = Proc.new {
        if (sent < file_size)
          left = file_size - sent
          if left > max_chunk
            left = max_chunk
          end

          #[:socket_inspect, #<UV::TCP:0x5558b3c914e0>, 11, #<UV::FS:0x5558b3c905e0>, 0, 32]
          #log!(:socket_inspect, self.socket, self.socket.fileno, fd, sent, left)

          #begin
          #  #if !sending
          #    bsent = sent
          #    sending = true

            #ffff = UV::FS::open(actual_wkndrfile, UV::FS::O_RDONLY, UV::FS::S_IREAD)
            #do |ffff|
              wkread = fd.read(left, sent)
              #fd.seek(wkread.length)
              self.socket.write(wkread) { |foo|
                #log!(:foo, foo)
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
                  end
                end
              }

                #UV::FS::sendfile(self.socket, fd, sent, left) { |xyx|
          #        begin
          #          #log!(:socket_post_send, xyx)

          #          if xyx.is_a?(UVError)
          #            #log!(:wtf_uv_e, xyx)

          #            #max_chunk = ((max_chunk / 2) + 1).to_i
          #            #log!(:sending_false_error, xyx)
          #            sending = false
          #          else
          #            sending = false
          #            sent += xyx.to_i
          #            #log!(:sending_false_sent, sent)
          #          end

          #          send_proc.call
          #        rescue => e
          #          log!(:eee, e)
          #        end
                #}

          #  #end
          #rescue UVError => e#resource temporarily unavailable
          #  log!(:wtf_uv_e, e)
          #  #max_chunk = ((max_chunk / 2) + 1).to_i
          #  sending = false
          #end
        else
          log!(:close_fd_close, fd)

          #fd.close
          #fd = nil
          #self.socket.read_stop
          #self.socket.close
          #self.socket = nil

          #idle.stop
          self.processing_handshake = true
          log!(:close_fd_close)
        end
      }
      #end

      send_proc.call

      log!(:socket_post_post, self)
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

          if filename == "/" || filename[0, 2] == "/~"
            filename = "/index.html"
          end

          requested_path = "#{@required_prefix}#{filename}"
          UV::FS.realpath(requested_path) { |resolved_filename|
            if resolved_filename.is_a?(UVError) || !resolved_filename.start_with?(@required_prefix)
              response_bytes = server.match_dispatch(filename)

              self.socket && self.socket.write(response_bytes) {
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

  def subscribe_to_wkndrfile(wkndrfile_path)
    log!(:subscribe_to_wkndrfile, wkndrfile_path)

    begin
      wkparts = wkndrfile_path.split("~", 2)  

      if wkndrfile_path == "/"
        reqd_wkfile = "Wkndrfile"
      else
        reqd_wkfile_user = wkparts[1].scan(/[a-z]/).join #TODO: better username support??
        reqd_wkfile = "/var/tmp/chroot/home/#{reqd_wkfile_user}/Wkndrfile"
      end

      UV::FS.realpath(reqd_wkfile) { |actual_wkndrfile|
        begin
          if actual_wkndrfile.is_a?(UVError)
            log!(:desktop_connection_wkndrfile_path_error, actual_wkndrfile)
          else
            log!(:subscribe_to_wkndrfile, wkndrfile_path, actual_wkndrfile)

            ffff = UV::FS::open(actual_wkndrfile, UV::FS::O_RDONLY, UV::FS::S_IREAD)
            wkread = ffff.read(102400)

            #log!(:ffff, ffff)
            log!(:outgoing_wkndrfile, wkread.length, wkread)

            begin
              did_parse = Kernel.eval(wkread)
              log!(:outbound_party_parsed_ok, did_parse)
              self.write_typed({"party" => wkread})
            rescue => e
              log!(:outbound_party_parsed_bad, e)
            end

            ffff.close
            @fsev = UV::FS::Event.new
            @fsev.start(actual_wkndrfile, 0) do |path, event|
              if event == :change
                @fsev.stop
                subscribe_to_wkndrfile(wkndrfile_path)
              end
            end
          end
        rescue => e
          log!(:desktop_connection_wkndrfile_realpath_error, e, e.backtrace)
        end
      }
    rescue => e
      log!(:desktop_connection_wkndrfile_subscribe_error, e, e.backtrace)
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
            log!(:got_msg, typed_msg)

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
                subscribe_to_wkndrfile(wkndrfile_req)

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
                      'file' => '/usr/bin/ruby',
                      'args' => ['/var/lib/wkndr/Thorfile', 'getty', @pid],
                      'detached' => true,
                      'env' => []
                    })

                    if @pending_resize
                      FastTTY.resize(@ftty[0], @pending_resize[0], @pending_resize[1])
                      @pending_resize = nil
                    end

                    @ps.spawn do |sig|
                      log!("exit #{sig}")

                      @pid = nil
                      @ps = nil
                    end

                    @stdin_tty.read_start do |bout|
                      log!(:AAA, bout)

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
        #log!(:send_ping)
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
