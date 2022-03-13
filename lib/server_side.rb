#

class ServerSide < Wkndr
  #NOTE: abstract-base-bits, class method wierdness
  def self.process_stacks!
    if @stacks_to_care_about
      running_stacks = @stacks_to_care_about.find_all { |rlb| rlb.running }
      if running_stacks.length > 0
        bb_ret = true
        running_stacks.each { |rlb| bb_ret = (bb_ret && rlb.signal) }
        bb_ret
      else
        return true
      end
    else
      return true
    end
  end

  def self.startup_serverside(args)
    log!(:server_side, self, Object.object_id, args)

    if args.include?("--no-server")
      @run_clientside_fps = true
      return
    end

    if args.include?("--no-client")
      @idle_runloop = true
    end

    if args.include?("--and-client") || args.empty?
      @run_clientside_fps = true
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
    @trap = UV::Signal.new
    
    @trap.start(UV::Signal::SIGINT) do
      log!(:foop)
      @keep_running = false
    end

    if @run_clientside_fps
      @timer = UV::Timer.new
      fps = 1000.0000/60.0000
      @timer.start(fps, fps) do
        rez = self.server_side_tick!

        unless rez
          @keep_running = false
          @timer.stop
          @trap.stop
          a,b = *Wkndr.the_server
          if b
            b.halt!
          end
          log!(:rez_falsey_exit_now, a, b)
          UV.run(UV::UV_RUN_NOWAIT)
          UV.default_loop.stop
          false
        end
      end
    end
  end

  def self.block!
    @keep_running = true

    install_trap!

    while @keep_running
      #self.server_side_tick!

      #unless @run_clientside_fps
        self.process_stacks!
      #end

      run_mode = (@run_clientside_fps || @idle_runloop) ? UV::UV_RUN_ONCE : UV::UV_RUN_NOWAIT
      #run_mode = UV::UV_RUN_NOWAIT
      #run_mode = UV::UV_RUN_ONCE

      UV.run(run_mode)
    end

    UV.default_loop.stop
  end
end
