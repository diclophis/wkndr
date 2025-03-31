class ShapeProxy
  def initialize(gl, batcher, count)
    @count = count
    @xhapes = []
    @count.times { |i|
      @xhapes << batcher.at(gl, i)
    }

    reset
  end

  def reset
    @current_shape = 0
  end

  def deltap(*args)
    @xhapes[@current_shape].deltap(*args)
  end

  def deltas(*args)
    @xhapes[@current_shape].deltas(*args)
  end

  def deltar(*args)
    @xhapes[@current_shape].deltar(*args)
  end

  def next
    @current_shape += 1
  end

  def current_shape
    @current_shape
  end

  def count
    @count
  end
end
