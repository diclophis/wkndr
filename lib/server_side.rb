#

class ServerSide < Wkndr
  def self.startup_serverside(args)
    if args.include?("--no-server")
      return
    end

    server_args = args.find { |arg| arg[0,9] == "--server=" }

    safety_dir_arg = "public"

    if server_args
      _, safety_dir_arg = server_args.split("=")
    end

    stack = StackBlocker.new(true)
 
    if protocol_server = ProtocolServer.new(safety_dir_arg)
      stack.up(protocol_server)
      Wkndr.set_server(protocol_server)
    end

    runblock!(stack)
  end

  def self.install_trap!
    @trap = UV::Signal.new
    
    @trap.start(UV::Signal::SIGINT) do
      @keep_running = false
    end
  end

  def self.block!
    @keep_running = true

    install_trap!

    #NOTE: what is this doing????
    @t = UV::Timer.new
    @t.start(1, 1) do |x|
      #log!(:timer_serverside)
    end

    ##TODO
    foo = true
    while @keep_running
      common_cheese_process!

      #foo = self.cheese_cross!
    #  super

      UV.run(UV::UV_RUN_NOWAIT)
    #
    #  UV.run(UV::UV_RUN_ONCE)
    end

    log!(:WTFWTWFSDSDSDSD)

    #UV.run(UV::UV_RUN_ONCE)

    UV.default_loop.stop
  end

  def block!
    log!(:server_side_block_instance)
  end
end
