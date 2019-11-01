#

class StackBlocker
  def initialize(for_server)
    @for_server = for_server
    @stack = []
  end

  def up(o)
    @stack << o
  end

  def fps
    if @for_server
      1
    else
      1
    end
  end

  def running
    @stack.all? { |srb| 
      srb.running
    }
  end

  def did_connect(&block)
    if block
      @did_connect_proc = block
    else
      if @did_connect_proc
        @did_connect_proc.call
      end
    end
  end

  def halt!
    @stack.each { |srb| srb.halt! }
  end

  def shutdown
    @stack.each { |srb| srb.shutdown }
  end

  def update(gt = 0, dt = 0)
    @stack.each { |srb| srb.update(gt, dt) }
  end

  def cheese
    #TODO: remove for_server abstraction its broken
    if @for_server
      update
    else
      log!(:cheese_signal, self, self.class)

      signal
    end
  end
end
