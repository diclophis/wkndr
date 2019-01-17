#

class SocketStream
  def initialize(got_bytes_block)
    #log!(:InitSocketStream, got_bytes_block)

    #TODO: rename this
    @got_bytes_block = got_bytes_block

    #Proc.new { |bytes|
    #}

    @outbound_messages = []
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
    #begin
      log!(:process, bytes)

    #  process_as_msgpack_stream(bytes) { |typed_msg|
    #    @got_bytes_block.call(typed_msg)
    #  }
    #rescue => e
    #end
  end

  def write(msg_typed)
    log!(:WRITE_SS, msg_typed)
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

    unpacked_length = MessagePack.unpack(all_bits_to_consider) do |result|
      yield result if result
    end

    @left_over_bits = all_bits_to_consider[unpacked_length, all_l]
  end
end
