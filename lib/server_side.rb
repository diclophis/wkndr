#

class ServerSide < Wkndr
  #def self.open_client!(stack, w, h)
  #  log!(:client, w, h)

  #  #stack = StackBlocker.new
  #  gl = GameLoop.new
  #  stack.up(gl)

  #  socket_stream = SocketStream.create_websocket_connection { |typed_msg|
  #    gl.event(typed_msg)
  #  }

  #  stack.did_connect {
  #    socket_stream.did_connect
  #  }

  #  stack.up(socket_stream)

  #  gl.emit { |msg|
  #    socket_stream.write(msg)
  #  }

  #  gl.open("wkndr", w, h, 120)

  #  #window.update { |gt, dt|
  #  #  gl.update(gt, dt)
  #  #}
  #  #stack.up(window)

  #  #stack.up(client)

  #  #stack
  #end

  desc "server", ""
  def server(w = 512, h = 512)
    log!(:outerserver, w, h)

    stack = StackBlocker.new(true)
    #stack.fps = 60

    ServerSide.start_server(stack)

    stack
  end
  method_added :server

  default_command :server
end

Wkndr.update_with_timer!(ServerSide.start(ARGV))

#Wkndr.block!
