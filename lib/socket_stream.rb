#

class SocketStream
  def initialize(got_bytes_block)
    @got_bytes_block = got_bytes_block

    @outbound_messages = []

    @left_over_bits = nil
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
      @got_bytes_block.call(typed_msg)
    }
  end

  def write(msg_typed)
    @outbound_messages << msg_typed
  end

  def running
    !@halting
  end

  def halt!
    log!(:halt_socket_stream)
    @halting = true
  end

  def shutdown
  end

  def update(gt = nil, dt = nil)
    #NOOP: ??
  end

  def process_as_msgpack_stream(bytes)
    all_bits_to_consider = (@left_over_bits || "") + bytes
    all_l = all_bits_to_consider.length

    unpacked_typed = []
    unpacked_length = MessagePack.unpack(all_bits_to_consider) do |result|
      if result
        unpacked_typed << result
      end
    end

    @left_over_bits = all_bits_to_consider[unpacked_length, all_l]

    unpacked_typed
  end
end
