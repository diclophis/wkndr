#

class Wkndr < Base
  def gameloop
    gl = GameLoop.new(self)
    gl
  end

  def window(name, x, y, fps)
    gl = gameloop
    window = Window.new("wkndr", x, y, fps, gl)
    yield window, gl
    window
  end
end
