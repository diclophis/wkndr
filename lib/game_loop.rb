#

class GameLoop
  def feed_state!(bytes)
    if @websocket_singleton_proc
      @websocket_singleton_proc.call(bytes)
    end
  end

  def process_as_msgpack_stream(bytes)
    all_bits_to_consider = (@left_over_bits || "") + bytes
    all_l = all_bits_to_consider.length

    #small_subset_to_consider = all_bits_to_consider
    #[0, 12800000]
    #considered_subset_length = small_subset_to_consider.length

    unpacked_length = MessagePack.unpack(all_bits_to_consider) do |result|
      yield result if result
    end

    @left_over_bits = all_bits_to_consider[unpacked_length, all_l]
  end
end

