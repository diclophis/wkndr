class SpinComponent
  def initialize(total, widget, component, speed)
    @total = total
    @widget = widget
    @component = component
    @speed = speed
  end

  def widget
    @widget
  end

  def component
    @component
  end

  def speed
    @speed
  end

  def speed=(x)
    @speed = x
  end

  def total
    @total
  end
end

class GizmoSystem
  def initialize(store, selector)
    @transit_speed = 0.1
    @selector = selector
  end

  def spin_speed=(x)
    @selector.each { |_e, cube, pos, spin|
      spin.speed = x
    }
  end

  def transit_speed=(x)
    @transit_speed = x
  end

  def process(gt, dt)
    @selector.each { |_e, cube, pos, spin|
      cube.deltar(
        0, Math.cos((gt * 3.0) + (spin.widget * 3.0)), Math.sin(gt * spin.component), gt * spin.speed
      )
      cube.deltap(pos.x + Math.sin(gt), pos.y + Math.cos(gt), pos.z + Math.tan((gt * @transit_speed) + spin.widget))
      ###, pos.y, pos.z + Math.sin(gt * (spin.widget + 1)))
      cube.deltas(1.25 + Math.sin(gt + spin.widget), 1.25 + Math.sin(gt + spin.widget), 1.25 + Math.sin(gt + spin.widget))
    }
  end
end

Wkndr.nonce {
  Wkndr.client_side { |gl|
    gl.open_default_view!
    gl.open_default_editor!
    gl.open_default_logger!

    @sprite_bit = SpriteComponent.new("resources/texel_checker.png")

    @store = StorageManager.new
    @transformer = TransformerSystem.new(@store)
    @exhaust = ExhaustSystem.new(@sprite_bit, @store, 0.025, @particleBitmap, @particleLayer)
    @movement = MovementSystem.new(@store)
    @exhaust_layer = @store.watch(ExhaustComponent, PositionComponent, RandomColorComponent)
    @hunter_layer = @store.watch(HunterComponent, PositionComponent, RandomColorComponent)
    @color = RandomColorComponent.new

    @last_l = 0

    @spawn_proc = Proc.new { |r, x, y, c|
      @store.add(
        HunterComponent.new(r),
        PositionComponent.new(x, y, 0),
        VelocityComponent.from_angle(r * 2.0 * 3.14).mul(500.0),
        @sprite_bit,
        TransformComponent.new(1.0),
        RandomColorComponent.from_color(c)
      )
    }

    @spinny_things = @store.watch(MeshProxy, PositionComponent, SpinComponent)
    @gizmo = GizmoSystem.new(@store, @spinny_things)

    xs = 2
    ys = 3
    zs = 4

    @instances = xs * ys * zs

    i = 0
    a = Cube.new(gl, 1.0, 1.0, 1.0, 1.0)
    @batcher_a = CubicBatchingSystem.new(@store, a, @instances)

    xs.times { |xd|
      ys.times { |yd|
        zs.times { |zd|
          p = PositionComponent.new((-xs * 0.5 * 2.7) + (xd * 2.7).to_f, (-ys * 0.5 * 2.7) + (yd * 2.7).to_f, (-zs * 0.5 * 2.7) + (zd * 2.7).to_f)
          @store.add(
            @batcher_a.at(i),
            p,
            SpinComponent.new(@instances, i, rand, 100.0 * rand)
          )

          i += 1
        }
      }
    }
  }

  Wkndr.server_side { |gl|
    @ticks = 0
  }
}

Wkndr.client_side { |gl|
  gl.event { |channel, msg|
    case channel
      when "spawn"
        @spawn_proc.call(*msg) if (@spawn_proc && @store)
    end
  }

  gl.update { |global_time, delta_time, sw, sh|
    gl.mousep { |xyl|
      x, y, l = *xyl

      if (l == 1)
        spawn_proc_args = [
          rand,
          x,
          y,
          @color.color
        ]

        @spawn_proc.call(*spawn_proc_args)
        gl.emit({"spawn" => spawn_proc_args})
      end
    }

    gl.drawmode {
      gl.threed {
        #raise "First Error"

        #gl.lookat(1, 45.0 + Math.sin(global_time), 33.0, 45.0 + Math.cos(global_time), 0.0, 0.1, 0.0, 50.0 + (1.0 + Math.sin(global_time * 0.25) * 5.0))
        gl.lookat(1, 45.0, 3.0, 45.0, 0.0, 0.1, 0.0, 50.0)

        #@spinny_things.each { |e, a, _b, _c|
        #  a.draw(false)
        #}
        @batcher_a.draw(@instances)
        #@batcher_b.draw
        #@batcher_c.draw
      }

      gl.twod {
        @exhaust_layer.each { |e, _x, p, c|
          gl.draw_circle(10.0, p.x, p.y, p.z, *c.color)
        }

        @hunter_layer.each { |e, _h, p, c|
          gl.draw_circle(20.0, p.x, p.y, p.z, *c.color)
        }
      }
    }

    @transformer.process(global_time, delta_time)
    @exhaust.process(global_time, delta_time)
    @movement.process(global_time, delta_time)
    @gizmo.process(global_time, delta_time)
  }
}

Wkndr.server_side { |gl, server|
  server.wsb("/") do |cn, phr|
  end

  server.raw("/status") do |cn, phr|
    Protocol.ok("ONLINE\n") #TODO: present SHA1 of existing code somehow?????
  end

  server.raw("/about") do |cn, phr|
    #raise "Server First Error"

    mab = Markaby::Builder.new
    mab.html5 "lang" => "en" do
      mab.head do
        mab.title "about"
      end

      mab.body do
        mab.h1 "what is wkndr"
        mab.p "it is a new hypertext application platform"
        mab.a "href" => "/" do
          "//////"
        end
      end
    end
    Protocol.ok(mab.to_s)
  end

  server.live("/sevengui", "wkndr sevengui") { |cn, phr, mab|
    mab.a(:href => "/sevengui") do
      mab.h1 "sevengui example"
    end

    mab.ul do
      mab.li do
        "bap bar: " + cn.session["gt"].inspect
      end
    end
  }
}
