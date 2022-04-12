#

class WslaySocketStream < SocketStream
  def shutdown
    if @socket
      @socket.close
      @socket = nil
    end

    if @t
      @t.stop
      @t.close
      @t = nil
    end
  end

  def halt!
    @halting = super
  end

  def connect!(wp)
    wslay_callbacks = Wslay::Event::Callbacks.new

    @last_buf = ""

    wslay_callbacks.recv_callback do |buf, len|
      # when wslay wants to read data
      # buf is a cptr, if your I/O gem can write to a C pointer you have to write at most len bytes into it
      # and return the bytes written
      # or else return a mruby String or a object which can be converted into a String via to_str
      # and be up to len bytes long
      # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when there is nothing to read
      max_sub_buf = @last_buf.slice!(0, len)
      max_sub_buf
    end
    
    wslay_callbacks.on_msg_recv_callback do |msg|
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
        dispatch_next_events(msg[:msg])
      else
        #??????
      end
    end

    wslay_callbacks.send_callback do |buf|
      # when there is data to send, you have to return the bytes send here
      # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when sending would block
      #begin
        if @socket
          @socket.try_write(buf)
        else
          0
        end
      #rescue UVError => e
      #  log!(:wslay_send_callback_err, e)
      #  0
      #end
    end
    
    @client = Wslay::Event::Context::Client.new wslay_callbacks
    @phr = Phr.new

    @host = '127.0.0.1'
    @port = 8000

    #log!(:connecting_to, @host, @port)

    on_read_start = Proc.new { |b|
      if b && b.is_a?(UVError)
        if @halting
          shutdown
        else
          restart_connection!
        end
      else
        if b && b.is_a?(String)
          handle_bytes!(b)
        end
      end
    }

    on_connect = Proc.new { |connection_broken_status|
      if @halting
      elsif connection_broken_status
        restart_connection!
      else
        write_ws_request! {
          #begin
            reset_handshake!
            @socket.read_start(&on_read_start)
            did_connect(wp) #NOTE: this is where client reqs new Wkndrfile
          #rescue => e
          #  log!(:wslay_socket_stream_write_ws_request_error, e, e.backtrace)
          #end
        }
      end
    }

    @try_connect = Proc.new {
      @socket = UV::TCP.new
      address = UV.ip4_addr(@host, @port)
      @socket.connect(address, &on_connect)
    }

    restart_connection!
  end

  def restart_connection!
    @t = UV::Timer.new
    @t.start(1000, 0) {
      @try_connect.call
    }
  end

  def handle_bytes!(b)
    if @processing_handshake
      @ss += b
      offset = @phr.parse_response(@ss)
      case offset
      when Fixnum
        #TODO??? !!!!! !!!! SECURITY #TODO
        #unless WebSocket.create_accept(key).securecmp(phr.headers.to_h.fetch('sec-websocket-accept'))
        #   raise Error, "Handshake failure"
        #end
        @processing_handshake = false
        @last_buf += @ss[offset..-1]
        proto_ok = (@client.recv != :proto)
        unless proto_ok
          #@gl.log!(:wslay_handshake_proto_error)
          shutdown
        end
      when :incomplete
        #log!("incomplete")
      when :parser_error
        #TODO: !!! log!(:parser_error, offset)
        shutdown
      end
    else
      @last_buf += b
      proto_ok = (@client.recv != :proto)
      unless proto_ok
        #TODO: !!! log!(:wslay_handshake_proto_error)
        shutdown
      end
    end
  end

  def reset_handshake!
    @ss = ""
    @processing_handshake = true
  end

  def write_ws_request!
    path = "/ws-msgpack"
    key = B64.encode(Sysrandom.buf(16)).chomp!
    @socket.write("GET #{path} HTTP/1.1\r\nHost: #{@host}:#{@port}\r\nConnection: Upgrade\r\nUpgrade: websocket\r\nSec-WebSocket-Version: 13\r\nSec-WebSocket-Key: #{key}\r\n\r\n") {
      yield
    }
  end

  def running
    !@halting
  end

  def write_packed(bytes)
    @client.queue_msg(bytes, :binary_frame)
    @client.send
  end
end

class SocketStream
  def self.socket_klass
    WslaySocketStream
  end
end
