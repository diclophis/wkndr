#

class StackBlocker
  def initialize
    @stack = []
  end

  def up(o)
    @stack << o
  end

  def running
    @stack.all? { |srb| srb.running }
  end

  def halt!
    @stack.all? { |srb| srb.halt! }
  end

  def shutdown
    @stack.all? { |srb| srb.shutdown }
  end

  def update
    @stack.all? { |srb| srb.update }
  end
end
