#

module ECS
  class Camera
  end

  class Entity
  end

  class StorageManager
    attr_accessor :things
    attr_accessor :things_to_components
    attr_accessor :components_to_things
    attr_accessor :multi_components_to_things
    attr_accessor :watches

    def initialize
      self.things = []
      self.things_to_components = {}
      self.components_to_things = {}
      self.multi_components_to_things = {}
      self.watches = {}
    end

    def add(thing, *compos)
      self.things << thing

      self.attach_components(thing, *compos)

      thing
    end

    def attach_components(thing, *compos)
      thing_to_compos = self.things_to_components[thing]

      unless thing_to_compos
        thing_to_compos = []
        self.things_to_components[thing] = thing_to_compos
      end

      klasses = []
      compos.each { |compo|
        compo_klass = compo.class
        klasses << compo_klass

        thing_to_compos << compo

        self.single_klass_cache(compo_klass) << thing
      }

      self.multi_klass_cache(*klasses) << thing

      self.watches.each { |klasses, watched_things|
        if (compos.collect { |compo| compo.class } & klasses) == klasses
          watched_things << [thing, compos]
        end
      }

      thing
    end

    def remove(thing)
      self.things.delete(thing)

      if attached_compos = self.things_to_components.delete(thing)
        klasses = []
        attached_compos.each { |attached_compo|
          klasses << attached_compo.class
        }
      
        self.detach_components(thing, *klasses)
      end
    end

    def detach_components(thing, *compo_klasses)
      self.multi_components_to_things.each { |multi_compo_klasses, things|
        compo_klasses.each { |compo_klass|
          self.single_klass_cache(compo_klass).delete(thing)

          if multi_compo_klasses.include?(compo_klass)
            things.delete(thing)
          end
        }
      }
    end

    def single_klass_cache(compo_klass)
      compo_klass_to_things = self.components_to_things[compo_klass] 
      unless compo_klass_to_things
        compo_klass_to_things = []
        self.components_to_things[compo_klass] = compo_klass_to_things
      end

      compo_klass_to_things
    end

    def multi_klass_cache(*klasses)
      multi_compo_klass_to_things = self.multi_components_to_things[klasses] 
      unless multi_compo_klass_to_things
        multi_compo_klass_to_things = []
        self.multi_components_to_things[klasses] = multi_compo_klass_to_things
      end

      multi_compo_klass_to_things
    end

    def each_having_all(*klasses)
      found_things = self.multi_klass_cache(*klasses)
      found_things.each { |thing|
        yield thing, self.things_to_components[thing]
      }
      found_things.count
    end

    def each_having(*klasses)
      found_things = []
      klasses.each { |compo_klass|
        found_things += single_klass_cache(compo_klass)
      }
      found_things.uniq!
      found_things.each { |thing|
        yield thing, self.things_to_components[thing] #.select { |a| klasses.include?(a.class) }
      }
      found_things.count
    end

    def watch(*klasses)
      self.watches[klasses] ||= []
      self.watches[klasses]
    end
  end

  class CameraFollowSystem
    attr_accessor :camera
    attr_accessor :target

    def initialize
    end

    def process(gt, dt)
    end
  end

  class MovementSystem
    attr_accessor :store
    attr_accessor :selector

    def initialize(store)
      #self.store = store
      self.selector = store.watch(PositionComponent, VelocityComponent)
    end

    def process(gt, dt)
      #self.store.each_having(*self.selector) 
      self.selector.each { |thing, components|
        _, position, velocity, _, _ = *components

        #log!(position, velocity)

        position.add(velocity.dup.mul(dt))
        position.r += (velocity.r * dt)
      }
    end
  end

  class TransformerSystem
    attr_accessor :store
    attr_accessor :selector

    def initialize(store)
      self.store = store
      self.selector = [TransformComponent]
    end

    def process(gt, dt)
      self.store.each_having(*self.selector) { |thing, components|
        transform,_ = *components

        #position.add(velocity.dup.mul(dt))
        #position.rotation += (velocity.rotation * dt)
      }
    end
  end

  class OrderingSystem
    attr_accessor :compare_proc
    attr_accessor :items
    attr_accessor :item_components

    def initialize(&the_compare_proc)
      self.compare_proc = the_compare_proc
      reset!
    end

    def reset!
      self.items = []
      self.item_components = {}
      @i = 0
    end

    def order_by(key, component)
      self.item_components[key] = component

      ## Iterate through the length of the array, push into method
      if @i == 0
        self.items[@i] = key
      else
        ## beginning with the second element items[i]
        j = @i - 1

        # If element to left of key is larger then
        # move it one position over at a time
        while j >= 0 and self.compare_proc.call(self.item_components[self.items[j]], component)
          self.items[j + 1] = self.items[j]
          j = j - 1
        end

        # Update key position
        self.items[j+1] = key
      end

      @i += 1
    end
  end

  class ByIndexSystem
    attr_accessor :process_proc

    def initialize(&the_process_proc)
      self.process_proc = the_process_proc
      reset!
    end

    def reset!
      @i = 0
    end

    def process(item)
      self.process_proc.call(item, @i)

      @i += 1
    end
  end

  class VectorComponent
    attr_accessor :x, :y, :z

    def initialize(x, y, z)
      self.x = x
      self.y = y
      self.z = z
    end

    def self.from(vec)
      self.new(vec.x, vec.y, vec.z)
    end

    def add(vec)
      self.x += vec.x
      self.y += vec.y
      self.z += vec.z
      self
    end

    def sub(vec)
      self.x -= vec.x
      self.y -= vec.y
      self.z -= vec.z
      self
    end

    def invert
      self.x *= -1
      self.y *= -1
      self.z *= -1
      self
    end

    def mul(scalar)
      self.x *= scalar
      self.y *= scalar
      self.z *= scalar
      self
    end

    def div(scalar)
      if (scalar === 0) then
        self.x = 0
        self.y = 0
        self.z = 0
      else
        self.x /= scalar
        self.y /= scalar
        self.z /= scalar
      end

      self
    end

    def norm
      length = self.length

      if (length === 0) then
        self.x = 1
        self.y = 0
        self.z = 0
      else
        self.div(length)
      end

      self
    end

    def rotateZ(angle)
      nx = self.x * Math.cos(angle) - self.y * Math.sin(angle)
      ny = self.x * Math.sin(angle) + self.y * Math.cos(angle)

      self.x = nx
      self.y = ny
    
      self
    end

    def lengthSq
      self.x * self.x + self.y * self.y + self.z * self.z
    end

    def length
      Math.sqrt(self.lengthSq)
    end

    def distanceSq(vec)
      dx = self.x - vec.x
      dy = self.y - vec.y
      dz = self.z - vec.z
      dx * dx + dy * dy + dz * dz
    end

    def distance(vec)
      Math.sqrt(self.distanceSq(vec))
    end

    def angleZ
      Math.atan2(self.y, self.x)
    end

    def crossZ(vec)
      self.x * vec.y - self.y * vec.x

      #self.class.new 
      #  y * vec.z - z * vec.y, 
      #  z * vec.x - x * vec.z, 
      #  x * vec.y - y * vec.x
    end

    def dotZ(vec)
      self.x * vec.x + self.y * vec.y + self.z * vec.z
      #x * vec.x + y * vec.y + z * vec.z
      #+ w * vec.w
    end
  end

  class VectorWithRotationComponent < VectorComponent
    attr_accessor :r
    def initialize(x = 0, y = 0, z = 0, r = 0)
      super(x, y, z)
      self.r = r 
    end
  end

  class PositionComponent < VectorWithRotationComponent
  end

  class VelocityComponent < VectorWithRotationComponent
  end

  class ColorComponent
    attr_accessor :color

    def initialize(r, g, b, a)
      self.color = [r, g, b, a]
    end
  end

  class RandomColorComponent < ColorComponent
    attr_accessor :color

    def initialize
      super(rand * 255.0, rand * 255.0, rand * 255.0, 255.0)
    end
  end

  class RandomSpinComponent
    attr_accessor :axis
    attr_accessor :angle

    def initialize
      self.axis = [0, 1, 0]
      self.angle = 45
    end
  end

  class TagComponent
    attr_accessor :label

    def initialize(the_label)
      self.label = the_label
    end
  end

  class CircleComponent
    attr_accessor :radius

    def initialize(the_radius)
      self.radius = the_radius
    end
  end

  class SpriteComponent
    attr_accessor :frame
    attr_accessor :props

    def initialize(frame = nil, props = nil)
      self.frame = frame
      self.props = props
      #{
      #  :visible => true,
      #  :position => nil,
      #  :rotation => 0,
      #  :scale => 1,
      #  :tint => 255,
      #  :alpha => 1
      ## :l, :n ????
      #}
    end
  end

  class TransformComponent
    attr_accessor :transformer
    attr_accessor :remaining

    def initialize(transformer)
      self.transformer = transformer
      self.remaining = transformer.duration
    end
  end

  class BountyComponent
  end

  class HunterComponent
    attr_accessor :target
    attr_accessor :distance
    attr_accessor :speed
    attr_accessor :agi
    attr_accessor :color

    def initialize
      self.speed = 250.0 * (1.0 + rand / 4.0)
      self.agi = (3.1457 / 48.0) * (1.0 + rand / 4.0)
      self.color = 255 * (rand / 1.0)
    end
  end
end
