#

module ECS
  class Entity
  end

  class StorageManager
    #attr_accessor :things
    #attr_accessor :things_to_components
    #attr_accessor :components_to_things
    #attr_accessor :multi_components_to_things
    #attr_accessor :watches

    def initialize
      reset!
    end

    def reset!
      @things = []
      @things_to_components = {}
      @components_to_things = {}
      @multi_components_to_things = {}
      @watches ||= {}
      @watches.each { |k,v|
        v.clear
      }
    end

    def count
      @things.length
    end

    def add(*compos)
      thing = Entity.new

      @things << thing
      attach_components(thing, *compos)

      thing
    end

    def attach_components(thing, *compos)
      #thing_to_compos = self.things_to_components[thing]

      #unless thing_to_compos
      #  thing_to_compos = []
      #  self.things_to_components[thing] = thing_to_compos
      #end

      #klasses = []
      #compos.each { |compo|
      #  compo_klass = compo.class
      #  klasses << compo_klass

      #  thing_to_compos << compo

      #  self.single_klass_cache(compo_klass) << thing
      #}

      #self.multi_klass_cache(*klasses) << thing

      @watches.each { |klasses, watched_things|
        if (compos.collect { |compo| compo.class } & klasses) == klasses
          watched_things << [thing, *compos.select { |a| klasses.include?(a.class) }]
        end
      }

      thing
    end

    def remove(thing)
      @things.delete(thing)

      #if attached_compos = self.things_to_components.delete(thing)
      #  klasses = []
      #  attached_compos.each { |attached_compo|
      #    klasses << attached_compo.class
      #  }
      #
      #  self.detach_components(thing, *klasses)
      #end


      @watches.each { |klasses, watched_things|
        watched_things.reject! { |watched_thing, *compos|
          thing == watched_thing
        }
      }
    end

    def detach_components(thing, *compo_klasses)
      #self.multi_components_to_things.each { |multi_compo_klasses, things|
      #  compo_klasses.each { |compo_klass|
      #    self.single_klass_cache(compo_klass).delete(thing)

      #    if multi_compo_klasses.include?(compo_klass)
      #      things.delete(thing)
      #    end
      #  }
      #} #TODO: clear watches
    end

    #def single_klass_cache(compo_klass)
    #  compo_klass_to_things = self.components_to_things[compo_klass] 
    #  unless compo_klass_to_things
    #    compo_klass_to_things = []
    #    self.components_to_things[compo_klass] = compo_klass_to_things
    #  end

    #  compo_klass_to_things
    #end

    #def multi_klass_cache(*klasses)
    #  multi_compo_klass_to_things = self.multi_components_to_things[klasses] 
    #  unless multi_compo_klass_to_things
    #    multi_compo_klass_to_things = []
    #    self.multi_components_to_things[klasses] = multi_compo_klass_to_things
    #  end

    #  multi_compo_klass_to_things
    #end

    #def each_having_all(*klasses)
    #  found_things = self.multi_klass_cache(*klasses)
    #  found_things.each { |thing|
    #    yield thing, self.things_to_components[thing]
    #  }
    #  found_things.count
    #end

    #def each_having(*klasses)
    #  found_things = []
    #  klasses.each { |compo_klass|
    #    found_things += single_klass_cache(compo_klass)
    #  }
    #  found_things.uniq!
    #  found_things.each { |thing|
    #    yield thing, self.things_to_components[thing]
    #  }
    #  found_things.count
    #end

    def watch(*klasses)
      @watches[klasses] ||= []
      @watches[klasses]
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
    #attr_accessor :store
    #attr_accessor :selector

    def initialize(store)
      @selector = store.watch(PositionComponent, VelocityComponent)
    end

    def process(gt, dt)
      @selector.each { |thing, position, velocity|
        position.add(velocity.mul(dt))
      }
    end
  end

  class TransformerSystem
    #attr_accessor :store
    #attr_accessor :selector

    def initialize(store)
      @store = store
      @selector = store.watch(TransformComponent)
    end

    def process(gt, dt)
      expired_things = []

      @selector.each { |thing, transform|
        if transform.expired(dt)
          #transform.transformer.end && transform.transformer.end(entity);
          #transform.transformer = transform.transformer.next;

          #if (!transform.transformer) {
          #  entity.remove(Transform);
          #  return;
          #}

          #transform.remaining += transform.transformer.duration;

          #expired_things << thing
        
          @store.remove(thing)
        end
      }

      #expired_things.each { |expired_thing|
      #  #log!(:store_l, self.store.things.length)
      #}
    end
  end

  class ExhaustSystem
    #attr_accessor :store
    #attr_accessor :frame
    #attr_accessor :layer
    #attr_accessor :selector
    #attr_accessor :cooldown
    #attr_accessor :timer

    def initialize(store, cooldown, frame, layer)
      @store = store
      @selector = store.watch(HunterComponent, PositionComponent, VelocityComponent, RandomColorComponent)
      @cooldown = cooldown
      @timer = 0
      @index = 0
    end

    def process(gt, dt)
      @timer += dt
      should_emit =  @timer > @cooldown
      allowed_emit = 16

      current_index = 0

      @selector.each { |thing,  _hunter, position, velocity, color|
        #velocity.add(VectorComponent.from_angle(0.5 - VectorComponent.signed_random(1.0)).mul(5.0))

        #velocity.rotateZ(dt * 10.0 * Math.sin(gt * 2.0))

        #if (current_index == (@index % @selector.length)) && should_emit && allowed_emit > 0
        if allowed_emit > 0 && should_emit
          @index += 1
          allowed_emit -= 1

          direction = VectorComponent.from_angle(velocity.angleZ - 3.14 + VectorComponent.signed_random(3.0)).mul(velocity.length * 0.25)
          @store.add(
            ExhaustComponent.new,
            PositionComponent.from(position),
            VelocityComponent.from(direction),
            SpriteComponent.new,
            TransformComponent.new(0.33),
            color
          )
        end

        current_index += 1
      }


      if should_emit
        @timer = 0
      end
    end
  end

  class OrderingSystem
    #attr_accessor :compare_proc
    #attr_accessor :items
    #attr_accessor :item_components

    def initialize(&the_compare_proc)
      @compare_proc = the_compare_proc
      reset!
    end

    def reset!
      @items = []
      @item_components = {}
      @i = 0
    end

    def order_by(key, component)
      @item_components[key] = component

      ## Iterate through the length of the array, push into method
      if @i == 0
        @items[@i] = key
      else
        ## beginning with the second element items[i]
        j = @i - 1

        # If element to left of key is larger then
        # move it one position over at a time
        while j >= 0 and @compare_proc.call(@item_components[@items[j]], component)
          @items[j + 1] = @items[j]
          j = j - 1
        end

        # Update key position
        @items[j+1] = key
      end

      @i += 1
    end
  end

  class ByIndexSystem
    #attr_accessor :process_proc

    def initialize(&the_process_proc)
      @process_proc = the_process_proc
      reset!
    end

    def reset!
      @i = 0
    end

    def process(item)
      @process_proc.call(item, @i)

      @i += 1
    end
  end

  class VectorComponent
    #attr_accessor :x, :y, :z

    def initialize(x, y, z)
      @x = x
      @y = y
      @z = z
    end

    def x
      @x
    end

    def y
      @y
    end

    def z
      @z
    end

    def self.from(vec)
      new(vec.x, vec.y, vec.z)
    end

    def self.from_angle(angle)
      new(Math.cos(angle), Math.sin(angle), 0)
    end

    def self.signed_random(scale = 1.0)
      (rand - 0.5) * scale
    end

    def add(vec)
      @x += vec.x
      @y += vec.y
      @z += vec.z
      self
    end

    def sub(vec)
      @x -= vec.x
      @y -= vec.y
      @z -= vec.z
      self
    end

    def invert
      @x *= -1
      @y *= -1
      @z *= -1
      self
    end

    def mul(scalar)
      #@x *= scalar
      #@y *= scalar
      #@z *= scalar
      #self
      self.class.new(@x * scalar, @y * scalar, @z * scalar)
    end

    def div(scalar)
      if (scalar === 0) then
        @x = 0
        @y = 0
        @z = 0
      else
        @x /= scalar
        @y /= scalar
        @z /= scalar
      end

      self
    end

    def norm
      length = @length

      if (length === 0) then
        @x = 1
        @y = 0
        @z = 0
      else
        div(length)
      end

      self
    end

    def rotateZ(angle)
      nx = @x * Math.cos(angle) - @y * Math.sin(angle)
      ny = @x * Math.sin(angle) + @y * Math.cos(angle)

      @x = nx
      @y = ny
    
      self
    end

    def lengthSq
      @x * @x + @y * @y + @z * @z
    end

    def length
      Math.sqrt(lengthSq)
    end

    def distanceSq(vec)
      dx = @x - vec.x
      dy = @y - vec.y
      dz = @z - vec.z
      dx * dx + dy * dy + dz * dz
    end

    def distance(vec)
      Math.sqrt(distanceSq(vec))
    end

    def angleZ
      Math.atan2(@y, @x)
    end

    def crossZ(vec)
      @x * vec.y - @y * vec.x

      #self.class.new 
      #  y * vec.z - z * vec.y, 
      #  z * vec.x - x * vec.z, 
      #  x * vec.y - y * vec.x
    end

    def dotZ(vec)
      @x * vec.x + @y * vec.y + @z * vec.z
      #x * vec.x + y * vec.y + z * vec.z
      #+ w * vec.w
    end
  end

  class VectorWithRotationComponent < VectorComponent
    #attr_accessor :r

    def initialize(x = 0, y = 0, z = 0, r = 0)
      super(x, y, z)
      @r = r 
    end
  end

  class PositionComponent < VectorWithRotationComponent
  end

  class VelocityComponent < VectorWithRotationComponent
  end

  class ColorComponent
    #attr_accessor :color

    def initialize(r, g, b, a)
      @color = [r, g, b, a]
    end

    def self.from_color(color)
      r, g, b, a = *color
      self.new(r, g, b, a)
    end

    def color
      @color
    end
  end

  class RandomColorComponent < ColorComponent
    #attr_accessor :color

    def initialize(r=nil, g=nil, b=nil, a=nil)
      super(r || (rand * 255.0), g || (rand * 255.0), b || (rand * 255.0), a || 255.0)
    end
  end

  #class RandomSpinComponent
  #  #attr_accessor :axis
  #  #attr_accessor :angle

  #  def initialize
  #    @axis = [0, 1, 0]
  #    @angle = 45
  #  end
  #end

  class TagComponent
    #attr_accessor :label

    def initialize(the_label)
      @label = the_label
    end
  end

  class ExhaustComponent
  end

  class CircleComponent
    #attr_accessor :radius

    def initialize(the_radius)
      @radius = the_radius
    end
  end

  class SpriteComponent
    #attr_accessor :frame
    #attr_accessor :props

    def initialize(frame = nil, props = nil)
      @frame = frame
      @props = props

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
    #attr_accessor :transformer
    #attr_accessor :remaining

    #def initialize(transformer)
    def initialize(remaining)
      #self.transformer = transformer
      #self.remaining = transformer.duration

      @remaining = remaining
    end

    def expired(dt)
      @remaining -= dt
      @remaining <= 0
    end
  end

  class BountyComponent
  end

  class HunterComponent
    #attr_accessor :target
    #attr_accessor :distance
    #attr_accessor :speed
    #attr_accessor :agi
    #attr_accessor :color

    def initialize(r)
      @speed = 250.0 * (1.0 + r / 4.0)
      @agi = (3.1457 / 48.0) * (1.0 + r / 4.0)
      @color = 255 * (r / 1.0)
    end
  end
end
