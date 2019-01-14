#

class WslaySocketStream < SocketStream
  def shutdown
    if @socket && @socket.has_ref?
      @socket.read_stop 
      @socket.close
      @socket = nil
    end
  end

  def connect!
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
      #@gl.log!(:msg, msg)

      if msg[:opcode] == :binary_frame
        #NOTE!!!!!!! get back to this refactor
        #self.feed_state!(msg[:msg])
        log!(:inb_client_from_outb, self, @got_bytes_block)
        @got_bytes_block.call(msg[:msg])
      else
        log!(msg[:opcode])
      end
    end

    wslay_callbacks.send_callback do |buf|
      # when there is data to send, you have to return the bytes send here
      # the I/O object must be in non blocking mode and raise EAGAIN/EWOULDBLOCK when sending would block
      begin
        if @socket
          @socket.try_write(buf)
        else
          0
        end
      rescue UVError => e
      #  self.disconnect!
        log!(e)
        0
      end
    end
    
    @client = Wslay::Event::Context::Client.new wslay_callbacks
    @phr = Phr.new

    host = '127.0.0.1'
    port = 8000

    @address = UV.ip4_addr(host, port)

    on_read_start = Proc.new { |b|
      if b && b.is_a?(UVError)
        log!(:retry, b, @halting)
        if !@halting
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
        log!(:halting, connection_broken_status)
        @t.stop
      elsif connection_broken_status
        log!(:broken, connection_broken_status)
      else
        @t.stop
        write_ws_request!
        reset_handshake!
        @socket.read_start(&on_read_start)
      end
    }

    @try_connect = Proc.new {
      @socket = UV::TCP.new
      @socket.connect(@address, &on_connect)
    }

    restart_connection!
  end

  def restart_connection!
    @t = UV::Timer.new
    @t.start(1000, 1000) {
      if @halting
        @t.stop
      else
        @try_connect.call
      end
    }
  end

  def handle_bytes!(b)
    #@gl.log!([:raw, b.length])

    if @processing_handshake
      @ss += b
      offset = @phr.parse_response(@ss)
      case offset
      when Fixnum
        log!(@phr.headers)
        #TODO???
        #unless WebSocket.create_accept(key).securecmp(phr.headers.to_h.fetch('sec-websocket-accept'))
        #   raise Error, "Handshake failure"
        #end
        @processing_handshake = false
        @last_buf += @ss[offset..-1]
        proto_ok = (@client.recv != :proto)
        unless proto_ok
          @gl.log!(:wslay_handshake_proto_error)
          @socket.close
        end
      when :incomplete
        log!("incomplete")
      when :parser_error
        log!(:parser_error, offset)
        spindown!
      end
    else
      @last_buf += b
      proto_ok = (@client.recv != :proto)
      unless proto_ok
        log!(:wslay_handshake_proto_error)
        @socket.close
      end
    end
  end

  def reset_handshake!
    @ss = ""
    @processing_handshake = true
  end

  def write_ws_request!
    path = "/ws"
    key = B64.encode(Sysrandom.buf(16)).chomp!
    log!(@address)
    @socket.write("GET #{path} HTTP/1.1\r\nHost: #{@address.sin_addr}:#{@address.sin_port}\r\nConnection: Upgrade\r\nUpgrade: websocket\r\nSec-WebSocket-Version: 13\r\nSec-WebSocket-Key: #{key}\r\n\r\n")
  end

  def running_game
    nil
  end

  def running
    !@halting
  end

  def update
    if some_outbound_messages = @outbound_messages.slice!(0, 1)
      unless some_outbound_messages.empty?
        write_raw(*some_outbound_messages)
      end
    end
  end

  def write_raw(*msg_typed)
    begin
      if @client
        msg = MessagePack.pack(*msg_typed)
        @client.queue_msg(msg, :binary_frame)
        outg = @client.send
        outg
      end
    rescue Wslay::Err => e
      log!(e)
    end
  end

  def halt!
    @halting = true
  end
end

class SocketStream
  def self.socket_klass
    WslaySocketStream
  end
end
