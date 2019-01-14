#

class GameLoop
  def play(gt = 0, dt = 0, &block)
    if block
      @play_proc = block
    else
      if @play_proc
        @play_proc.call(gt, dt)
      end
    end
  end

  def feed_state!(bytes)
    if @websocket_singleton_proc
      @websocket_singleton_proc.call(bytes)
    end
  end
end

