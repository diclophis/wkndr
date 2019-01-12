#

class MainMenu < GameLoop
  def initialize(*args)
    super(*args)

    @hero = args[0]

    lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
  end

  def play(global_time, delta_time)
    drawmode {
      twod {
        button(0.0, 0.0, 250.0, 20.0, @hero.experience_button) {
          @hero.intensify_experience!
        }
      }
    }
  end
end
