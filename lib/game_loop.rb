#


class GameLoop
  def update(gt = 0, dt = 0, &block)
    #log!(:already_a_gl_dummy, block)
    #$stdout.write("\nWTF\n#{block.inspect}\n")

    if block
      #$stdout.write("\n111\n")
      @play_proc = block
    else
      if @play_proc
        #$stdout.write("\n222\n")

        @play_proc.call(gt, dt)
      end
    end
  end

  def event(msg = nil, &block)
    if block
      @event_proc = block
    else
      if @event_proc
        @event_proc.call(msg)
      end
    end
  end

  def emit(msg = nil, &block)
    if block
      @emit_proc = block
    else
      if @emit_proc
        @emit_proc.call(msg)
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
