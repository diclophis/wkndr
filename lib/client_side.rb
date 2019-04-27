#
def log!(*args, &block)
  $stdout.write(args.inspect)
  $stdout.write("\n")
  yield if block
end

class ClientSide < Wkndr
  def self.open_client!(stack, w, h)
    log!(:client, w, h)

    #stack = StackBlocker.new
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

    gl.open("wkndr", w, h, 120)

    Wkndr.play(stack, gl)

    #window.update { |gt, dt|
    #  gl.update(gt, dt)
    #}
    #stack.up(window)

    #stack.up(client)

    #stack
  end

  desc "client", ""
  def client(w = 512, h = 512)
    log!(:outerclient, w, h)

    #client = Wkndr.client(w, h)
    stack = StackBlocker.new(false)
    #stack.fps = 60


    ClientSide.open_client!(stack, w.to_i, h.to_i)

    #Wkndr.play(stack, gl)
    stack
  end

  method_added :client
  default_command :client
end

Wkndr.update_with_timer!(ClientSide.start(ARGV))
Wkndr.block!
