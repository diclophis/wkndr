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

  def self.create_websocket_connection(&block)
    ss = socket_klass.new(block)
    ss.connect!
    ss
  end

  def process(bytes = nil)
    process_as_msgpack_stream(bytes).each { |typed_msg|
      channels = typed_msg.keys
      channels.each do |channel|
        cmsg = typed_msg[channel]
        #NOTE: channels are as follows
        #
        #  1 stdout of connected tty
        #  2 stderr of connected tty
        #  p is the Wkndrfile code stream
        #  * everything else gets sent to user-defined handler
        case channel
          when 1,2
            self.write_tty(cmsg)
          when "p"
            did_parse = Kernel.eval(cmsg)

        else
          @got_bytes_block.call(cmsg)
        end
      end
    }

    #GC.start
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

  def update(gt = nil, dt = nil)
    if some_outbound_messages = @outbound_messages.slice!(0, 1)
      unless some_outbound_messages.empty?
        write_typed(*some_outbound_messages)
      end
    end
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
