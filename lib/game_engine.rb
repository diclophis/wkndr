#

class GameEngine
  PRIMARY  = 0x000000FF

  def initialize(*args)
  end

  def self.process_time(gl, global_time, delta_time)
    #@camera.update(gl, global_time, delta_time, 1.5, @game.player_position)
    #case @game.update(gl, global_time, delta_time)
    #  when :level_up
    #    @start_game_proc.call(@game.level + 1, :level_up)
    #  when :level_down
    #    @start_game_proc.call(@game.level - 1, :level_down)
    #end
  end

  def self.draw_threed(gl)
    #@camera.lookat(gl, @game.player_position, 100.0)
    #@game.draw_threed(gl, @camera)
  end

  def self.draw_twod(gl)
    #@game.draw_twod(gl)
  end

  def self.start(gl) #, distance, cube, shapes, batcher, shape_batchers, starting_level = 1, direction = :level_up)
    #@start_game_proc ||= Proc.new { |maze_level, direction_inner|
    #  @camera = GameCamera.new
    #  @game = self.new(distance, maze_level, cube, shapes, batcher, shape_batchers, direction_inner)
    #  if maze_level > 0
    #    gl.emit({"mkmaze" => @game.level})
    #  end
    #}
    #@start_game_proc.call(starting_level, direction)
  end

  def self.event(channel, msg)
    #if @game
    #  case channel
    #    when "position"
    #      @game.track_other_players!(msg)
    #    when "maze"
    #      @game.load_maze!(*msg)
    #  end
    #end
  end

  def update(gl, global_time, delta_time)
    :keep_running
  end

  def draw_threed(gl) #, camera)
    #@camera_angle = camera.angle
    #@shapes.each { |i, shape|
    #  shape.reset
    #}

    ##if @maze_level > 0
    ##  if @maze && @px && @py
    ##    ((@px-(@maze_draw_distance))..(@px+@maze_draw_distance)).each do |x|
    ##      ((@py-(@maze_draw_distance) + @maze_draw_distance_h)..(@py+@maze_draw_distance) + @maze_draw_distance_h).each do |y|
    ##        if x>=0 && x<@maze_s && y>=0 && y<@maze_s
    ##          a = Math.atan2(y - @py, x - @px)
    ##          deg = (a * (180.0 / 3.1457))
    ##          if (@camera_angle - deg).abs < 100.0 || ((@px - x).abs < 2) && ((@py - y).abs < 2)
    ##            cell = @maze[x][y]
    ##            unless cell == 0
    ##              primary = (cell & PRIMARY)
    ##              if shape = @shapes[primary]
    ##                shape.deltar(0.0, 1.0, 0.0, 0.0)
    ##                shape.deltap(x, 0, y)
    ##                shape.deltas(1.0, 1.0, 1.0)
    ##                shape.next #draw(false)
    ##              end
    ##            end
    ##          end
    ##        end
    ##      end
    ##    end
    ##  end
    ##else
    ##  ((@px-(@maze_draw_distance))..(@px+@maze_draw_distance)).each do |x|
    ##    ((@py-(@maze_draw_distance) + @maze_draw_distance_h)..(@py+@maze_draw_distance) + @maze_draw_distance_h).each do |y|
    ##      a = Math.atan2(y - @py, x - @px)
    ##      deg = (a * (180.0 / 3.1457))
    ##      if (@camera_angle - deg).abs < 100.0 || ((@px - x).abs < 2) && ((@py - y).abs < 2)
    ##        shape = @shapes[0]
    ##        shape.deltar(0.0, 1.0, 0.0, 0.0)
    ##        shape.deltap(x, -0.125, y)
    ##        shape.deltas(1.0, 1.0, 1.0)
    ##        #shape.deltar(0.0, 1.0, 0.0, 0.0)
    ##        #shape.deltap(x * 10.0, -0.125 * 14.0, y * 10.0)
    ##        #shape.deltas(10.0, 10.0, 10.0)
    ##        shape.next #draw(false)
    ##      end
    ##    end
    ##  end
    ##end

    #@shape_batchers.each { |i, shape_batcher|
    #  shape_batcher.draw(@shapes[i].current_shape)
    #}

    #@players.each { |key, rpv|
    #  player_position, player_velocity = *rpv

    #  @cube.reset
    #  @cube.deltar(0.0, 1.0, 0.0, Math.atan2(player_velocity[0], player_velocity[2]) * (180.0/3.1457))
    #  @cube.deltap(*player_position)
    #  @cube.deltas(0.125, 0.125, 0.125)
    #  @cube.next #@cube.draw(false)
    #}


    ##TODO
    ##@players.each { |key, rpv|
    ##  player_position, player_velocity = *rpv
    ##  @cube.deltar(0.0, 1.0, 0.0, (Math.atan2(player_velocity[0], player_velocity[2]) * (180.0/3.14)) + 0.0)
    ##  @cube.deltap(*player_position)
    ##  @cube.deltas(0.125, 0.125, 0.125)
    ##  @cube.next #@cube.draw(false)
    ##}

    #@batcher.draw(@cube.current_shape)
  end

  def draw_twod(gl)
    #gl.label(game_status)
  end

  def game_status
    #@maze_level.to_s + " | " + 
    #@ticks.to_s + " | " +
    #("%04.1f" % ((@last_delta_time || 0.0) * 1000.0)) + " | " +
    #("%04.1f" % (@last_global_time || 0.0)) + " | " +
    #@sent.to_s + " | " +
    #@pressing.to_s + " | " + 
    #("%04.1f" % @camera_angle)
  end
end
