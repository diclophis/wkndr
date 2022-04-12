#

class Qe3eRigidBody
  def initialize(scene)
    @scene = scene
  end

  def add(box)
  end
end

class Qu3eBox
end

class Qu3eScene

  def initialize(fixed_dt = 1.0/60.0)
  end

  def create_rigid_body
    Qe3eRigidBody.new(self)
  end
  
end
