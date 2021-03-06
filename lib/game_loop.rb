#

class GameLoop
  attr_accessor :width, :height

  def update(gt = 0, dt = 0, sw = 0, sh = 0, &block)
    if block
      @play_proc = block
    else
      if @play_proc
        @play_proc.call(gt, dt, sw, sh)
      end
    end
  end

  def event(channel = nil, msg = nil, &block)
    if block
      @event_proc = block
    else
      if @event_proc
        @event_proc.call(channel, msg)
      end
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

    #log!(:INIT_WINDOW)

    socket_stream = SocketStream.create_websocket_connection(wp) { |channel, typed_msg|
      self.event(channel, typed_msg)
    }

    self.emit { |msg|
      socket_stream.write(msg)
    }

    socket_stream
  end

  def open_default_view!(fps = 0)
    #log!("wkndr", self.width, self.height, 0) # screenSize and FPS

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
