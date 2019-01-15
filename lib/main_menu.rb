#

class MainMenu < GameLoop
  def initialize(*args)
    super(*args)

    lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
  end

  def play(global_time, delta_time)
    drawmode {
      twod {
        button(0.0, 0.0, 250.0, 20.0, "start") {
          #TODO: onclick
        }
      }
    }
  end
end
