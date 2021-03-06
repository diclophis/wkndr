#

class GameCamera
  def initialize(follow_speed, look_speed)
    @follow_speed = follow_speed
    @look_speed = look_speed

    @camera_target = [0, 0, 0]
    @camera_position = [-0.0, 0, -3.0]
  end

  def update(gl, global_time, delta_time, height, player_position)
    @camera_target[0] += (player_position[0] - @camera_target[0]) * (1.0 * (player_position[0] - @camera_target[0]).abs) * @look_speed * delta_time
    @camera_target[2] += (player_position[2] - @camera_target[2]) * (1.0 * (player_position[2] - @camera_target[2]).abs) * @look_speed * delta_time

    @camera_position[0] += ((@camera_target[0] - @camera_position[0]) * @follow_speed * delta_time)
    @camera_position[1] = height
    @camera_position[2] += (((@camera_target[2] - 3.0) - @camera_position[2]) * @follow_speed * delta_time)
  end

  def lookat(gl, player_position, fov = 60.0)
    gl.lookat(1, *@camera_position, *@camera_target, fov)
  end

  def angle
    Math.atan2((@camera_target[2] - @camera_position[2]), (@camera_target[0] - @camera_position[0])) * (180.0 / 3.1457)
  end
end
