#

class Window < PlatformSpecificBits
  def initialize(*args)
    super(*args)

    #@world = World.new

    #@main_menu = MainMenu.new(@world.hero)

    @simple_boxes = SimpleBoxes.new(self)
    #@snake = Snake.new(self)
    #@cheese = ""
  end

  def play(global_time, delta_time)
    #@snake.play(global_time, delta_time)

    #if 0 == ((global_time * 0.33).to_i % 2)
      @simple_boxes.play(global_time, delta_time)
    #else

      #@world.play(global_time, delta_time)

      #@main_menu.play(global_time, delta_time)
    #end
  end

  def spindown!
    log! :foop
    @simple_boxes = nil
    GC.start
    super
  end
end

show! Window.new("window", 512, 512, 60)

#maze = maze.to_unicursal

#puts maze.to_s(:mode => :plain)
#puts maze.to_s(:mode => :unicode)
#puts maze.to_s(:mode => :lines)
