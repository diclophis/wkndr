##
$count = 0

class Window
  def initialize(name, x, y, fps, game_loop)
    should_raise = $count == 1
    log!(:chees77777, self, $count)
    $count += 1
    open(name, x, y, fps)

    raise "wtd" if should_raise

    #log!(:Window, game_loop)
    ##@world = World.new
    ##(@world.hero)
    #@main_menu = MainMenu.new
    ##@simple_boxes = SimpleBoxes.new(self)
    ##@snake = Snake.new(self)
    ##@cheese = ""

    @game_loop = game_loop
  end

  def running_game
    @game_loop
  end

  def play(global_time, delta_time)
    @game_loop.play(global_time, delta_time)
  end

  def running
    !@halting
  end

  def halt!
    log!(:halt_window)
    @halting = true
  end
end
