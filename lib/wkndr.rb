#

class Wkndr < Thor
  def self.client(gl = nil)
    log!(:client)

    stack = StackBlocker.new

    socket_stream = SocketStream.create_websocket_connection { |typed_msg|
      gl.event(typed_msg)
    }
    stack.up(socket_stream)

    gl.emit { |msg|
      socket_stream.write(msg)
    }

    window = Window.new("wkndr", 512, 512, 120)
    window.update { |gt, dt|
      gl.update(gt, dt)
    }

    stack.up(window)

    stack
  end

  def self.play(stack = nil, gl = nil, &block)
    log!(:play, stack, gl, block)

begin
raise "wtF"
rescue => e
  log!(:e, e.backtrace)
end

    if block && @gl
      block.call(@gl)
    elsif !@gl && !@stack
      @stack = stack
      @gl = gl

      #play { |_gl|
      #  gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
      #  gl.update { |global_time, delta_time|
      #    gl.drawmode {
      #      gl.threed {
      #      }
      #      gl.twod {
      #        gl.draw_fps(0, 0)
      #      }
      #    }
      #  }
      #}

      log!(:show!)
      Wkndr.show! @stack
    end
  end

  desc "something", ""
  def something
    log!(:something)

    stack = StackBlocker.new

    gl = GameLoop.new
    stack.up(gl)

    client = Wkndr.client(gl)
    stack.up(client)

    Wkndr.play(stack, gl)
  end
  method_added(:something) #TODO???
  default_command :something
end
