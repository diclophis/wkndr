#

class ServerSide < Wkndr
  def self.startup_serverside(args)
    if args.include?("--no-server")
      return
    end

    if args.include?("--no-client")
      @use_slow_loop = true
    end

    server_args = args.find { |arg| arg[0,9] == "--server=" }

    safety_dir_arg = "public"

    if server_args
      _, safety_dir_arg = server_args.split("=")
    end

    stack = StackBlocker.new

    gl = GameLoop.new
    stack.up(gl)
 
    if protocol_server = ProtocolServer.new(safety_dir_arg)
      stack.up(protocol_server)
      Wkndr.set_server([gl, protocol_server])
    end

    runblock!(stack)
  end

  def self.install_trap!
    @timer = UV::Timer.new
    fps = 1000.0/1.0
    @draw_this_tick = false

    @timer.start(fps, fps) do
      @draw_this_tick = true

      unless @keep_running
        @timer.stop
      end
    end

    @trap = UV::Signal.new
    
    @trap.start(UV::Signal::SIGINT) do
      @keep_running = false
    end
  end

  def self.block!
    @keep_running = true

    install_trap!

    ##TODO: trap exit condition from UI
    foo = true
    #foo = self.cheese_cross!
    #other_foo = common_cheese_process!
    #run_mode = @use_slow_loop ? UV::UV_RUN_ONCE : UV::UV_RUN_NOWAIT
    run_mode = UV::UV_RUN_ONCE
    while @keep_running
      foo = self.cheese_cross!

      #if @draw_this_tick
        other_foo = common_cheese_process!
        #if @draw_this_tick
        #@draw_this_tick = false
      #end

      #UV.run(UV::UV_RUN_NOWAIT)
      #UV.run(UV::UV_RUN_ONCE)
      #UV.run
      UV.run(run_mode)

      break unless (foo)
    end

    UV.default_loop.stop
  end
end
