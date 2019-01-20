#

#class Base < Thor
#  def server(*args)
#  end
#end

class Wkndr
  def self.client(gl = nil)
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

  #def self.start(args = nil, &block)
  #  #server = super(["server"])
  #  #stack.up(server)
  #  if args == nil && block
  #  else
  #    stack = super(args)
  #    self.show! stack
  #  end
  #end

  def self.play(stack = nil, gl = nil, &block)
    if block && @gl
      block.call(@gl)
    else
      @stack = stack
      @gl = gl

      Wkndr.show! @stack
    end
  end
end
