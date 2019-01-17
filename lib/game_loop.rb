#

class GameLoop
  def update(gt = 0, dt = 0, &block)
    if block
      @play_proc = block
    else
      if @play_proc
        @play_proc.call(gt, dt)
      end
    end
  end

  def running
    !@halting
  end

  def halt!
    @halting = true
  end

  def shutdown
  end
end

