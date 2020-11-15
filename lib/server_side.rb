#

class ServerSide < Wkndr
  def self.startup_serverside(args)
    if args.include?("--no-server")
      @run_clientside_fps = true
      return
    end

    if args.include?("--no-client")
      @idle_runloop = true
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
    if @run_clientside_fps
      @timer = UV::Timer.new
      fps = 1000.0/24.0
      @timer.start(fps, fps) do
        self.server_side_tick!
        unless @keep_running
          @timer.stop
        end
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

    while @keep_running
      #self.server_side_tick!

      unless @run_clientside_fps
        self.process_stacks!
      end

      run_mode = (@run_clientside_fps || @idle_runloop) ? UV::UV_RUN_ONCE : UV::UV_RUN_NOWAIT
      #run_mode = UV::UV_RUN_NOWAIT
      #run_mode = UV::UV_RUN_ONCE

      UV.run(run_mode)
    end

    UV.default_loop.stop
  end
end
