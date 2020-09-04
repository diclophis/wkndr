#

class GameCamera
  def initialize
    @camera_target = [0, 0, 0]
    @camera_position = [-0.0, 0, -3.0]
  end

  def update(gl, global_time, delta_time, height, player_position)
    follow_speed = 0.75
    follow_look_speed = 5.0

    @camera_target[0] += (player_position[0] - @camera_target[0]) * (1.0 * (player_position[0] - @camera_target[0]).abs) * follow_look_speed * delta_time
    @camera_target[2] += (player_position[2] - @camera_target[2]) * (1.0 * (player_position[2] - @camera_target[2]).abs) * follow_look_speed * delta_time

    @camera_position[0] += ((@camera_target[0] - @camera_position[0]) * follow_speed * delta_time)
    @camera_position[1] = height
    @camera_position[2] += (((@camera_target[2] - 2.25) - @camera_position[2]) * follow_speed * delta_time)
  end

  def lookat(gl, player_position)
    gl.lookat(1, *@camera_position, *@camera_target, 40.0)
  end
end
