#

class ServerSide < Wkndr
  def self.install_trap!
    @keep_running = true

    UV::Signal.new.start(UV::Signal::SIGINT) do
      @keep_running = false
    end
  end

  def self.block!
    install_trap!

    t = UV::Timer.new
    t.start(1, 1) do |x|
      #log!(:timer_serverside)
    end

    while @keep_running && foo = self.cheese_cross!
      super

      UV.run(UV::UV_RUN_NOWAIT)
    
      UV.run(UV::UV_RUN_ONCE)
    end

    UV.run(UV::UV_RUN_ONCE)
    UV.default_loop.stop
  end

  def self.startup_serverside(args)
    if args.include?("--no-server")
      return
    end

    server_args = args.find { |arg| arg[0,9] == "--server=" }

    wkndrfile_arg = nil

    if server_args
      _, wkndrfile_arg = server_args.split("=")
    end

    stack = StackBlocker.new(true)
 
    if protocol_server = ProtocolServer.new(wkndrfile_arg)
    #  Wkndr.set_server(a_server)
    #  Wkndr.the_server.subscribe_to_wkndrfile("/")
      stack.up(protocol_server)
    end

    runblock!(stack) if stack && stack.is_a?(StackBlocker) #TODO: fix odd start() dispatch case
  end

  def self.server_side
    yield
  end
end
