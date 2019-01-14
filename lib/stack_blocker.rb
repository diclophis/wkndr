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
    @stack.each { |srb| srb.halt! }
  end

  def shutdown
    @stack.each { |srb| srb.shutdown }
  end

  def update
    @stack.each { |srb| srb.update }
  end

  def running_game
    @stack.detect { |srb| srb.running_game }.running_game
  end
end
