#

class ServerSide < Wkndr
  #NOTE: abstract-base-bits, class method wierdness
  def self.process_stacks!
    r = nil

    if @stacks_to_care_about
      running_stacks = @stacks_to_care_about.find_all { |rlb| rlb.running }
      if running_stacks.length > 0
        #bb_ret = true
        running_stacks.each { |rlb|
          #bb_ret = (bb_ret && rlb.signal)
          #bb_ret = (bb_ret && rlb.signal)
          bb_ret = rlb.signal
          #Wkndr.log! [:bbret_server, bb_ret, rlb.class]

          r = r || bb_ret
        }
        #r = bb_ret
      end
    end

    #Wkndr.log! [:pcs, self, :server_side, r]

    r
  end

  def self.startup_serverside(args)
    #Wkndr.log! [:server_side, self, Object.object_id, args]

    if args.include?("--no-server")
      @run_clientside_fps = true
      return
    end


    if (args.include?("--and-client") && !args.include?("--no-client")) || args.empty?
      @run_clientside_fps = true
    else
      @idle_runloop = true
    end

    #if args.empty?
    #end

    server_args = args.find { |arg| arg[0,9] == "--server=" }

    safety_dir_arg = "public"

    if server_args
      _, safety_dir_arg = server_args.split("=")
    end

    stack = StackBlocker.new

    gl = GameLoop.new
    stack.up(gl)
 
    if protocol_server = ProtocolServer.new(gl, safety_dir_arg)
      #Wkndr.log! [:server_side2, :gl, gl, protocol_server, self]

      stack.up(protocol_server)
      Wkndr.set_server([gl, protocol_server])
    end

    runblock!(stack)
  end

  def self.install_trap!
    @trap = UV::Signal.new
    #Wkndr.log! [:foop_trap]
    
    @trap.start(UV::Signal::SIGINT) do
      Wkndr.log! [:foop_caught]
      @keep_running = false
    end

      if @run_clientside_fps
        @timer = UV::Timer.new
        #fps = 1000.0000/60.00001
        fps = 1000.0000/23.999
        #fps = 1000.0000
        @timer.start(fps, fps) do
          rez = self.server_side_tick!


          if rez
            Wkndr.log! [:rez_should_be_true_to_exit, rez]

            @keep_running = false
            @timer.stop
            @trap.stop
            a,b = *Wkndr.the_server
            if b
              b.halt!
            end
            #log!([:rez_falsey_exit_now, a, b])
            #UV.run(UV::UV_RUN_NOWAIT)
            #UV.default_loop.stop
            #@keep_running = false
          end
        end
      end

  end

  def self.block!
    @keep_running = true

    install_trap!

    Wkndr.log! [:going_for_ev_loop_start]

    while @keep_running
      #Wkndr.log! [:keep, @run_clientside_fps]

      #xyr = self.server_side_tick!
      #Wkndr.log! [:xyr, xyr]

      #unless @run_clientside_fps
        xyr = self.process_stacks!

          if xyr
            Wkndr.log! [:xyr, xyr]

            @keep_running = false
            @timer.stop if @timer
            @trap.stop if @trap
            a,b = *Wkndr.the_server
            if b
              b.halt!
            end
          end
      #end

      #TODO: sort this
      run_mode = (@run_clientside_fps || @idle_runloop) ? UV::UV_RUN_ONCE : UV::UV_RUN_NOWAIT

      #Wkndr.log! [:run_mode, run_mode, UV::UV_RUN_ONCE, UV::UV_RUN_NOWAIT]

      #run_mode = UV::UV_RUN_NOWAIT
      #run_mode = UV::UV_RUN_ONCE

      UV.run(run_mode)
    end

    Wkndr.log! [:going_for_ev_loop_stop, @keep_running]

    UV.default_loop.stop
  end
end
