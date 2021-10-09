#

class SocketStream
  def initialize(got_bytes_block)
    @got_bytes_block = got_bytes_block

    @outbound_messages = []

    @left_over_bits = ""
  end

  def self.socket_klass
    SocketStream
  end

  # single-binary client side native connection creator
  def self.create_websocket_connection(wp, &block)
    ss = socket_klass.new(block)
    ss.connect!(wp)
    ss
  end

  def dispatch_next_events(bytes = nil)
    #@clients_to_notify.each { |wkndrfile, clients|
    #  clients.each { |cn|
    #    cn.write_typed({"party" => wkread})
    #  }
    #}

    process_as_msgpack_stream(bytes).each { |typed_msg|
      channels = typed_msg.keys
      channels.each do |channel|
        cmsg = typed_msg[channel]
        #NOTE: channels are as follows
        #
        #  1 stdout of connected tty
        #  2 stderr of connected tty
        #  party is the Wkndrfile code stream
        #  * everything else gets sent to user-defined handler
        case channel
          when 1,2 #TODO: deprecate this loopback mechanism
            self.write_tty(cmsg)
          when "party" #TODO: rename this something not stupid
            begin
              wkndrfile_cstr = cmsg
              log!(:WTF2, cmsg.length)
              did_parse = Wkndr.wkndr_client_eval(wkndrfile_cstr)
              log!(:WTF3, did_parse, cmsg.length)
            rescue => e
              #log!(:cmsg_bad, e)
              #log!(e.backtrace)
              raise
            end

        else

          @got_bytes_block.call(channel, cmsg)

        end
      end
    }
  end

  def write(msg_typed)
    @outbound_messages << msg_typed
  end

  def running
    !@halting
  end

  def halt!
    @halting = true
  end

  def shutdown
  end

  def process_as_msgpack_stream(bytes)
    if bytes && bytes.length
      @left_over_bits += bytes

      unpacked_typed = []
      unpacked_length = MessagePack.unpack(@left_over_bits) do |result|
        if result
          unpacked_typed << result
        end
      end

      @left_over_bits.slice!(0, unpacked_length)

      unpacked_typed
    end
  end

  def update(gt = nil, dt = nil, sw = 0, sh = 0)
    if some_outbound_messages = @outbound_messages.slice!(0, 1)
      unless some_outbound_messages.empty?
        write_typed(*some_outbound_messages)
      end
    end
  end

  def did_connect(wkndrfile_path)
    #TODO: merge this with other bits
    #TODO: this is client side asking for file
    write_typed({"party" => wkndrfile_path})
  end

  def write_typed(*msg_typed)
    if connected
      msg = MessagePack.pack(*msg_typed)
      write_packed(msg)
    end
  end

  def connected
    @client
  end
end
