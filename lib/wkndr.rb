#

class Base < Thor
end

class Wkndr < Base
  def gameloop
    gl = GameLoop.new(self)
    gl
  end

  def window(name, x, y, fps, gl)
    window = Window.new("wkndr", x, y, fps, gl)
    yield window, gl
    window
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

    stack
  end

  def self.start(args)
    log!(:START, args)

    if args.empty?
      args = ["client_and_server"]
    end

    if run_loop_blocker = super(args)
      log!(:rl, self, run_loop_blocker)

      self.show! run_loop_blocker, run_loop_blocker.running_game
    end
  end
end
