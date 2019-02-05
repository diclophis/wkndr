#

class Wkndr < Thor
  desc "client", ""
  def client(w, h)
    log!(:outerclient, w, h)

    stack = StackBlocker.new

    gl = GameLoop.new
    stack.up(gl)

    client = Wkndr.client(gl, w.to_i, h.to_i)
    stack.up(client)

    Wkndr.play(stack, gl)
  end

  def self.client(gl = nil, w = 512, h = 512)
    log!(:client, w, h)

    stack = StackBlocker.new

    socket_stream = SocketStream.create_websocket_connection { |typed_msg|
      gl.event(typed_msg)
    }

    stack.did_connect {
      socket_stream.did_connect
    }

    stack.up(socket_stream)

    gl.emit { |msg|
      socket_stream.write(msg)
    }

    gl.open("wkndr", w, h, 120)

    #window.update { |gt, dt|
    #  gl.update(gt, dt)
    #}
    #stack.up(window)

    stack
  end

  def self.play(stack = nil, gl = nil, &block)
    log!(:play, stack, gl, block)

    if block && @gl
begin
      block.call(@gl)
rescue => e
  log!(:e, e, e.backtrace)
end
    elsif !@gl && !@stack
      @stack = stack
      @gl = gl

      play { |_gl|
        gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
        gl.update { |global_time, delta_time|
          gl.drawmode {
            gl.threed {
            }
            gl.twod {
              gl.draw_fps(0, 0)
            }
          }
        }
      }

      log!(:show!)
      Wkndr.show! @stack
    end
  end

  desc "server", ""
  def server(directory = "public")
    stack = StackBlocker.new

    #gl = GameLoop.new
    #stack.up(gl)

    #client = Wkndr.client(gl)
    #stack.up(client)

    server = Wkndr.server
    stack.up(server)

    Wkndr.play(stack, nil)
  end

  desc "something", ""
  def something
    log!(:something)

    stack = StackBlocker.new

    gl = GameLoop.new
    stack.up(gl)

    client = Wkndr.client(gl)
    stack.up(client)

    server = Wkndr.server
    stack.up(server)

    Wkndr.play(stack, gl)
  end
  method_added(:something) #TODO???
  default_command :something
end
