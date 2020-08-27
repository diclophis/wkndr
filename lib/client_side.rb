#

class ClientSide < Wkndr
  def self.startup_clientside(args)
    if args.include?("--no-client")
      return
    end

    client_args = args.find { |arg| arg[0,9] == "--client=" }

    party_args = args.find { |arg| arg[0,8] == "--party=" }

    w = 512
    h = 512
    wp = "Wkndrfile"

    if client_args
      a,b = client_args.split("=")
      w, h = (b.split("x"))
    end

    if party_args
      a,b = party_args.split("=")
      wp = b
    end

    stack = StackBlocker.new

    gl = GameLoop.new

    socket_stream = gl.connect_window!(w, h, wp)
    raise "unknown socket stream: TODO: fix this abstraction" unless socket_stream

    stack.up(gl)
    stack.up(socket_stream)

    Wkndr.set_client(gl)

    runblock!(stack)
  end
end
