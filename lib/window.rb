##

class Window < BaseWindow
  def initialize(name, x, y, fps, game_loop)
    super(name, x, y, fps)

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

  #def spinlock!
  #  #NOOP: TODO????
  #end

  #def spindown!
  #  log! :foop
  #  GC.start
  #  super
  #end

  def running
    !@halting
  end

  def halt!
    @halting = true
  end
end
