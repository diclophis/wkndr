#

class Polygon
  def self.centroid(coords)
    pt1 = coords[0]
    xt = pt1[0]
    yt = pt1[1]
    zt = pt1[2]
    closed = 0.0
    len = coords.length
    for i in 1...len
      if(pt1 != coords[i])
        xt += coords[i][0]
        yt += coords[i][1]
        zt += coords[i][2]
      else
        closed = 1.0
      end
    end
    len -= closed
    xt /= len
    yt /= len
    zt /= len
    
    return [xt,yt,zt]
  end
end
