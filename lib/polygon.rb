#

class Polygon
  def self.centroid(coords)
    pt1 = coords[0]
    xt = pt1.x
    yt = pt1.y
    zt = pt1.z
    closed = 0.0
    len = coords.length
    for i in 1...len
      if(pt1 != coords[i])
        xt += coords[i].x
        yt += coords[i].y
        zt += coords[i].z
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
