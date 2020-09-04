#

class AABB
  #TODO: abstract this
  def self.test(min_a, max_a, min_b, max_b)
    d1x = -min_b[0] - -max_a[0]
    d1y = -min_b[1] - -max_a[1]
    d2x = -min_a[0] - -max_b[0]
    d2y = -min_a[1] - -max_b[1]

    if (d1x > 0.0 || d1y > 0.0)
      return false
    elsif (d2x > 0.0 || d2y > 0.0)
      return false
    else
      a = (d2x - d1x).abs
      b = (d2y - d1y).abs
      if a > b
        return :y
      else
        return :x
      end
    end
  end
end
