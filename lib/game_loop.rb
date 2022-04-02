#

class GameLoop
  attr_accessor :width, :height
  attr_accessor :play_procs, :event_procs

  def update(cli, gt = 0, dt = 0, sw = 0, sh = 0, touchpoints = nil, &block)
    if cli && block 
      self.play_procs[cli] = block
      "installed #{cli}: #{block.object_id}"
    else
      if cli == false && self.play_procs
        self.play_procs.each { |cli, play_proc|
          rez = play_proc.call(gt, dt, sw, sh, touchpoints)
        }
      end
    end
  end

  def event(cli, channel = nil, msg = nil, &block)
    if cli && block
      #@event_proc = block
      self.event_procs[cli] = block
    else
      #if @event_proc
      self.event_procs.each { |cli_inner, event_proc|
        #log!(:FOOOO, cli, cli_inner, channel, msg, event_proc, block)
#[:FOOOO, "mkmaze", 1, nil, #<Proc:0x55caab044bf0>, nil]                                                               

        event_proc.call(channel, msg)
      }
      #end
    end
  end

  def emit(msg = nil, &block)
    if block
      @emit_proc = block
    else
      if @emit_proc
        @emit_proc.call(msg)
      end
    end
  end

  #TODO: de-nest these bits / refactor
  def running
    !@halting
  end

  def halt!
    @halting = true
  end

  def shutdown
  end

  def connect_window!(w, h, wp)
    self.width = w
    self.height = h

    self.play_procs = {}
    self.event_procs = {}

    #log!(:INIT_WINDOW, w, h, wp)

    socket_stream = SocketStream.create_websocket_connection(wp) { |channel, typed_msg|
      self.event(nil, channel, typed_msg)
    }

    self.emit { |msg|
      socket_stream.write(msg)
    }

    socket_stream
  end

  def open_default_view!(fps = 0)
    #log!("open_def_wkndr_win", self.width, self.height, 0) # screenSize and FPS

    #TODO: make this more modular ???
    self.open("wkndr", self.width.to_i, self.height.to_i, fps) # screenSize and FPS

    #self.update { |global_time, delta_time|
    #  self.drawmode {
    #    self.threed {
    #    }
    #    self.twod {
    #      self.draw_fps(0, 0)
    #      self.button(50.0, 50.0, 250.0, 20.0, "zzz #{'%0.7f' % delta_time}") {
    #        self.emit({"z" => "zzz"})
    #      }
    #    }
    #  }
    #}
  end
end
