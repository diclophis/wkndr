#

class StackBlocker
  def initialize
    @stack = []
  end

  def up(o)
    @stack << o
  end

  def running
    @stack.all? { |srb| 
      #log!(:running?, srb)
      srb.running
    }
  end

  def halt!
    log!(:sb_halt!)
    @stack.each { |srb| srb.halt! }
  end

  def shutdown
    @stack.each { |srb| srb.shutdown }
  end

  def update(gt, dt)
    @stack.each { |srb| srb.update(gt, dt) }
  end
end
