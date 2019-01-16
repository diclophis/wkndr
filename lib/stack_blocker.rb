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
    log!(:halt_stack_blocker)
    @stack.each { |srb| srb.halt! }
  end

  def shutdown
    @stack.each { |srb| srb.shutdown }
  end

  def update
    @stack.each { |srb| srb.update }
  end

  def running_game
    if first_game = @stack.detect { |srb| srb.running_game }
      first_game.running_game
    end
  end
end
