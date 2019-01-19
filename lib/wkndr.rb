#

class Base < Thor
  def server(*args)
  end
end

class Wkndr < Base
  desc "client", ""
  def client(gl = nil)
    log!(:create_client, gl)

    stack = StackBlocker.new

    socket_stream = SocketStream.create_websocket_connection { |typed_msg|
      gl.event(typed_msg)
    }
    stack.up(socket_stream)

    gl.emit { |msg|
      socket_stream.write(msg)
    }

    window = Window.new("wkndr", 512, 512, 60)
    window.update { |gt, dt|
      gl.update(gt, dt)
    }

    stack.up(window)

    stack
  end

  def self.start(args = nil, &block)
    stack = StackBlocker.new

    gl = GameLoop.new(self)
    stack.up(gl)

    server = super(["server"])
    stack.up(server)

    if block
      client = super(["client", gl])
      block.call(gl)
      stack.up(client)
    end

    self.show! stack
  end
end
