#

class Base < Thor
end

class Wkndr < Base
  def gameloop
    gl = GameLoop.new(self)
    gl
  end

  def window(name, x, y, fps, gl)
    wndw = Window.new("wkndr", x, y, fps, gl)
    yield wndw, gl
    wndw
  end

  #def web
  #  #log!(:in_web)
  #end

  desc "client", ""
  def client
    stack = StackBlocker.new

    gl = gameloop

    socket_stream = SocketStream.create_websocket_connection { |bytes|
      log!(:wss_goood, bytes)
    }
    stack.up socket_stream

    log! :gonna_opened_window, self, gl

    wlh = window("window", 512, 512, 60, gl) { |wndw|
      log! :did_window, self, gl

      gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
      cube = Cube.new(1.0, 1.0, 1.0, 5.0)
      gl.play { |global_time, delta_time|
        log! :play, self

        gl.drawmode {
          gl.threed {
            gl.draw_grid(10, 10.0)
            cube.draw(true)
          }
          gl.twod {
            gl.button(0.0, 0.0, 250.0, 20.0, "start #{global_time}") {
              log! :click
              socket_stream.write(["getCode"])
            }
          }
        }
      }

      #log! :casdasdasdasd, self
      #self.class.show!(stack, stack.running_game)
    }
    stack.up wlh
    log! :did_stackup, self, gl

    stack
  end

  def self.start(args)
    log!(:START, args)

    if args.empty?
      args = ["client_and_server"]
    end

    if run_loop_blocker = super(args)
      log!(:rl, self, run_loop_blocker, run_loop_blocker.running_game)

      #if args[0] == "server"
        self.show! run_loop_blocker, run_loop_blocker.running_game
      #end
    end
  end
end
