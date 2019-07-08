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

  desc "server [dir]", ""
  def server(dir = "public")
    stack = StackBlocker.new(true)

    self.class.start_server(stack, dir)

    Wkndr.the_server.subscribe_to_wkndrfile("/")

    stack
  end
  method_added :server

  desc "client", ""
  def client(*args)
    log!(:outerclient_on_serverside, args)
    nil
  end
  method_added :client
end
