#

class ClientSide < Wkndr
  def self.startup_clientside(args)
    if args.include?("--no-client")
      return
    end

    client_args = args.find { |arg| arg[0,9] == "--client=" }

    w = 512
    h = 512

    if client_args
      a,b = client_args.split("=")
      w, h = (b.split("x"))
    end

    stack = StackBlocker.new(false)

    self.open_client!(stack, w.to_i, h.to_i)

    runblock!(stack) if stack && stack.is_a?(StackBlocker) #TODO: fix odd start() dispatch case
  end

  def self.open_client!(stack, w, h)
    gl = GameLoop.new
    stack.up(gl)

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

    gl.open("wkndr", w, h, 10)

    gl.update { |global_time, delta_time|
      gl.drawmode {
        gl.threed {
        }
        gl.twod {
          gl.draw_fps(0, 0)
          gl.button(50.0, 50.0, 250.0, 20.0, "zzz #{global_time} #{delta_time}") {
            gl.emit({"z" => "zzz"})
          }
        }
      }
    }

    Wkndr.set_stack(stack)
    Wkndr.set_gl(gl)
  end

  def self.wizbang!
    self.show!(self.first_stack)
  end

  #def self.block!
  #  supblock = super
  #  UV.run(UV::UV_RUN_NOWAIT)
  #
  #  UV.run(UV::UV_RUN_ONCE)
  #  supblock
  #end
end
