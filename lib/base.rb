#

class Base < Thor
  def window(name, x, y, fps)
    gl = GameLoop.new(self)
    yield gl

    window = Window.new("wkndr", x, y, fps, gl)

    window
  end

  def default
    server = continous
    server
  end
    
  def client
    window("window", 512, 512, 60) { |gl|
      log! :in_opened_window, gl

      gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)

      gl.play { |global_time, delta_time|
        gl.drawmode {
          gl.twod {
            gl.button(0.0, 0.0, 250.0, 20.0, "start #{global_time}") {
              #TODO: onclick
              log! :click
            }
          }
        }
      }
    }
  end
end
