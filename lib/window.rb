##
$count = 0

class Window
  def initialize(name, x, y, fps)
    should_raise = $count == 1
    log!(:chees77777, self, $count)
    $count += 1
    open(name, x, y, fps)

    raise "wtd" if should_raise
  end

  def update(gt, dt)
    #TODO: reattach to game loop, multi-window support????
    #@game_loop.update(global_time, delta_time)
  end

  def running
    !@halting
  end

  def halt!
    log!(:halt_window)
    @halting = true
  end
end
