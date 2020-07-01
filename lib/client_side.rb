#

class ClientSide < Wkndr
  def self.startup_clientside(args)
    #log!(:start_clientside)

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

    gl = GameLoop.new

    socket_stream = gl.connect_window!(w, h)
    raise "unknown socket stream: TODO: fix this abstraction" unless socket_stream

    stack.up(gl)
    stack.up(socket_stream)

    Wkndr.set_client(gl)

    runblock!(stack)
  end
end
