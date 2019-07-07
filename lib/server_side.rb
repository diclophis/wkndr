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

    log!(:TRAPINSTALLED, self, @keep_running, @stacks_to_care_about)

i = UV::Idle.new

    while @keep_running && foo = self.cheese_cross!
      #log!(:serverside_block_open)

      super

      UV.run(UV::UV_RUN_ONCE)

#i.start {|x|
#}

      #t = UV::Timer.new
      #t.start(16, 0) do |x|
      #  #log!(:timer_serverside)
      #end

      #log!(:serverside_block_close)
    end

    #UV.run(UV::UV_RUN_ONCE)
    #UV.default_loop.stop
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
