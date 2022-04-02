#
#    super.touchDragged(unused, x, y, pointerIndex);
#    float deltaX  = (initialX - x);
#    float deltaY  = (initialY - y);
#    float rotationAngle = 360.0f * (float)(Math.sqrt(deltaX * deltaX + deltaY * deltaY)/screenDst);
#    while (rotationAngle < 0) {
#        rotationAngle += 360;
#    }
#    while (rotationAngle > 360) {
#        rotationAngle -= 360;
#    }
#
#    float alpha = (float)Math.atan2(deltaY,deltaX) * MathUtils.radiansToDegrees;
#
#    Quaternion q = new Quaternion(origCameraDirection, alpha);
#    Vector3 rotatedUp = origCameraUp.cpy();
#    q.transform(rotatedUp);
#
#    // rotatedUp is our actual rotation vector
#    Quaternion actualQ = new Quaternion(rotatedUp, rotationAngle);
#
#    Vector3 newCameraPosition = origCameraPosition.cpy(); 
#    actualQ.transform(newCameraPosition);
#    camera.position.set(newCameraPosition);
#
#    Vector3 newCameraDirection = origCameraDirection.cpy(); 
#    actualQ.transform(newCameraDirection);
#    camera.direction.set(newCameraDirection);
#
#    Vector3 newCameraUp = origCameraUp.cpy(); 
#    actualQ.transform(newCameraUp);
#    camera.up.set(newCameraUp);
#    return true;


class GameCamera
  def initialize(follow_speed, look_speed)
    @follow_speed = follow_speed
    @look_speed = look_speed

    @camera_target = [0, 0, 0]
    @camera_position = [-0.0, 0, -3.0]
  end

  def update(gl, global_time, delta_time, distance, height, player_position)
    @camera_target[0] += (player_position[0] - @camera_target[0]) * (1.0 * (player_position[0] - @camera_target[0]).abs) * @look_speed * delta_time
    @camera_target[2] += (player_position[2] - @camera_target[2]) * (1.0 * (player_position[2] - @camera_target[2]).abs) * @look_speed * delta_time
    
    #@camera_target[0] = player_position[0]
    #@camera_target[2] = player_position[2]

    #a = Math.atan2((@camera_position[2]) - @camera_target[2], (@camera_position[0]) - @camera_target[0])
    #deg = (a * (180.0 / 3.1457))
    #f = self.angle - a
    #fx = Math.sin(f) * 10.5 * delta_time
    #fy = Math.cos(f) * 10.5 * delta_time

    @camera_position[0] += (((@camera_target[0]) - @camera_position[0]) * @follow_speed * delta_time)
    #@camera_position[0] = (@camera_target[0] - 0.0)
    @camera_position[1] = height
    @camera_position[2] += (((@camera_target[2]) - distance - @camera_position[2]) * @follow_speed * delta_time)
    #@camera_position[2] = (@camera_target[2] - distance)
  end

  def lookat(gl, player_position, fov = 60.0)
    gl.lookat(1, *@camera_position, *@camera_target, fov)
  end

  def angle
    Math.atan2((@camera_target[2] - @camera_position[2]), (@camera_target[0] - @camera_position[0])) * (180.0 / 3.1457)
  end
end
