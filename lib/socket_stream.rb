#

class SocketStream
  def initialize(got_bytes_block)
    #log!(:InitSocketStream, got_bytes_block)

    @got_bytes_block = Proc.new { |bytes|
      process_as_msgpack_stream(bytes) { |typed_msg|
        got_bytes_block.call(typed_msg)
      }
    }

    @connected = true
    @outbound_messages = []
  end

  def self.socket_klass
    SocketStream
  end


  #def socket_klass
  #  WslaySocketStream
  #end

  def self.create_websocket_connection(&block)
    ss = socket_klass.new(block)
    ss.connect!
    ss
  end

  def write(msg_typed)
    log!(:WRITE_SS, msg_typed)
    @outbound_messages << msg_typed
  end

  def running_game
    nil
  end

  def running
    !@halting
  end

  def halt!
    @halting = true
  end

  def shutdown
  end

  def update
    #NOOP: ??
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
end
