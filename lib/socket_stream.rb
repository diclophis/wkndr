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
    log!(:raw_typed, typed_msg)

      channels = typed_msg.keys
      channels.each do |channel|
        cmsg = typed_msg[channel]
        case channel
          when 1,2
            self.write_tty(cmsg)
          when "p"
            #did_parse = Wkndr.parse!(cmsg)
            did_parse = Kernel.eval(cmsg)
            log!(:DidTheParseWkndr, did_parse)
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

      #all_bits_to_consider = (@left_over_bits || "") + bytes
      #all_l = all_bits_to_consider.length

      unpacked_typed = []
      unpacked_length = MessagePack.unpack(@left_over_bits) do |result|
        if result
          unpacked_typed << result
        end
      end

      #@left_over_bits = all_bits_to_consider[unpacked_length, all_l]
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
    #log!(:outbound, msg_typed)
    #begin
      if connected
        msg = MessagePack.pack(*msg_typed)

        write_packed(msg)
      end
    #rescue Wslay::Err => e
    #  log!(e)
    #end
  end

  def connected
    @client
  end
end
