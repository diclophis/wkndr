#

class Base < Thor
  def gameloop
    gl = GameLoop.new(self)
    #yield gl
    gl
  end

  def window(name, x, y, fps)
    gl = gameloop
    window = Window.new("wkndr", x, y, fps, gl)
    yield window, gl
    window
  end

  def default
    server = continous
    server
  end
    
  def client
    #TODO: refactor multi loop
    window("window", 512, 512, 60) { |window, gl|
      log! :in_opened_window, window, gl

      gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
      cube = Cube.new(1.0, 1.0, 1.0, 5.0)

      gl.play { |global_time, delta_time|
        gl.drawmode {
          gl.threed {
            gl.draw_grid(10, 10.0)
            cube.draw(true)
          }

          gl.twod {
            gl.button(0.0, 0.0, 250.0, 20.0, "start #{global_time}") {
              log! :click
            }
          }
        }
      }
    }
  end
end
