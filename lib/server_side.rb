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
    directory = args[0] || "public"

    log!(:startup_serverside, directory)

    stack = StackBlocker.new(true)
 
    if a_server = Server.run!(directory)
      Wkndr.set_server(a_server)
      Wkndr.the_server.subscribe_to_wkndrfile("/")
      stack.up(a_server)
    end

    runblock!(stack) if stack && stack.is_a?(StackBlocker) #TODO: fix odd start() dispatch case

    stack
  end
end
