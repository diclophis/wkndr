#

class StackBlocker
  attr_accessor :fps

  def initialize
    @stack = []
    self.fps = 15
  end

  def up(o)
    @stack << o
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
end
