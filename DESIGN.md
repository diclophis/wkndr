# new design

unit test everything
replace `log!` with better interface... logger instance, something mockable
re-impl libuv bindings


        if foo.is_a?(UVError)
        if foo.is_a?(UV::Req)

        address = UV.ip4_addr(host, port)
        @server = UV::TCP.new

        ev = UV::FS::Event.new

        realpath = UV::FS.realpath(requested_path, &handle_static_file(cn))
        UV::FS.realpath(reqd_wkfile) { |actual_wkndrfile|
        }

        fd = UV::FS::open(@actual_wkndrfile, UV::FS::O_RDONLY, UV::FS::S_IREAD)
        fd = UV::FS::open(filename, UV::FS::O_RDONLY, 0)

        t = UV::Timer.new

        trap = UV::Signal.new
        trap.start(UV::Signal::SIGINT) do

        UV.run(UV::UV_RUN_NOWAIT)
        UV.default_loop.stop


re-impl raylib bindings
non-vim/non-tty based editor !!!
beam assets over connection for parsing on client side
  factory dispatch controller action handler
  resource placeholder???

# thought bubbles on design on lib

```
#Wkndr.nonce {
#  Wkndr.client_side { |gl|
#    @store = StorageManager.new
#
#    @first = @store.add(Entity.new, TagComponent.new("1"), PositionComponent.new(0, 1, 0), RandomSpinComponent.new, RandomColorComponent.new)
#    @second = @store.add(Entity.new, TagComponent.new("2"), PositionComponent.new(0, 2, 0), RandomSpinComponent.new, RandomColorComponent.new)
#
#    @query = [TagComponent, PositionComponent, RandomSpinComponent, RandomColorComponent]
#
#    @shapes = []
#
#    16.times { |i|
#      @shapes  << @store.add(Entity.new, CircleComponent.new(16.0 + (i*6)), PositionComponent.new(0, 0, 0), RandomColorComponent.new)
#    }
#
#    @query_shapes = [CircleComponent, PositionComponent, RandomColorComponent]
#
#    @transform_rotate = TransformRotateSystem.new
#
#    @camera_one = @store.add(Camera.new, TagComponent.new("camera one"), PositionComponent.new(-10, 0, -10))
#    @camera_two = @store.add(Camera.new, TagComponent.new("camera two"), PositionComponent.new(10, 0, 10))
#
#    @camera_one_follow = CameraFollowSystem.new
#    @camera_one_follow.camera = @camera_one
#    @camera_one_follow.target = @first
#
#    @camera_two_follow = CameraFollowSystem.new
#    @camera_two_follow.camera = @camera_two
#    @camera_two_follow.target = @second
#
#    @twod_grid_system = ByIndexSystem.new
#
#    @first_ordering_system = OrderingSystem.new
#
#    @second_ordering_system = OrderingSystem.new
#
#    gl.open_default_view!
#  }
#}
#
#
#Wkndr.client_side { |gl|
#
#@compare_position_proc = Proc.new { |a, b|
#  a.position[1] < b.position[1]
#}
#
#@compare_radius_proc = Proc.new { |a, b|
#  a.radius > b.radius
#}
#
#  twod_proc = Proc.new {
#    @first_ordering_system.items.each { |thing_sorted_by_screen_position|
#      shape, position, color = @store.things_to_components[thing_sorted_by_screen_position]
#      gl.draw_circle(shape.radius, *position.position, *color.color)
#    }
#
#    gl.draw_fps(15, 15)
#  }
#
#  @first_ordering_system.compare_proc = @compare_position_proc
#
#  @second_ordering_system.compare_proc = @compare_radius_proc
#
#  @twod_grid_system.process_proc = Proc.new { |a, i|
#    max_w = 64
#
#    width = 4
#    height = (@shapes.length / width).to_i
#    offset = 64.0
#
#    x = (i % width)
#    y = ((i / width).to_i)
#
#    a.position[0] = (256.0 + (max_w * 0.5) - ((width * offset) * 0.5)) + (x * offset)
#    a.position[1] = (256.0 + (max_w * 0.5) - ((height * offset) * 0.5)) + (y * offset)
#  }
#
#  @first_ordering_system.reset!
#  @second_ordering_system.reset!
#  @twod_grid_system.reset!
#
#  @store.each_having_all(*@query_shapes) { |thing, components|
#    shape, position, color = *components
#    @second_ordering_system.order_by(thing, shape)
#  }
#
#  @second_ordering_system.items.each { |thing_sorted_by_size|
#    shape, position, color = @store.things_to_components[thing_sorted_by_size]
#    @twod_grid_system.process(position)
#    @first_ordering_system.order_by(thing_sorted_by_size, position)
#  }
#
#  @first_ordering_system.items.each { |thing_sorted_by_screen_position|
#    shape, position, color = @store.things_to_components[thing_sorted_by_screen_position]
#  }
#
#  gl.update { |global_time, delta_time|
#    
#    gl.drawmode {
#      gl.twod(&twod_proc)
#    }
#  }
#}
#
#Wkndr.server_side { |server|
#  server.wsb("/") do |cn, phr|
#  end
#
#  server.raw("/status") do |cn, phr|
#    "OK\n"
#  end
#
#  server.live("/todos", "todos") do |cn, phr, mab|
#    mab.h1 "stuff todo w/ name"
#
#    mab.input "type" => "text"
#
#    mab.ul do
#      10.times do |i|
#        mab.li do
#          mab.label do
#            mab.input "type" => "checkbox"
#            mab.text "Task #{i+1}"
#          end
#        end
#      end
#    end
#  end
#}

#Wkndr.client_side { |gl|
#}

#Wkndr.client_side { |gl|
  #total_msg = 0

  #gl.event { |typed_msg|
  #  total_msg += 1
  #}

  #gl.update { |global_time, delta_time|
  #  gl.lookat(1, 7.0 + Math.sin(global_time * 0.133) * 11.0, 7.0 + Math.cos(global_time), 11.0 - Math.cos(global_time * 1.111) * 3.0, 0.0, 1.0, 0.0, 33.0)

  #  speed = 100.0 # + (global_time * 10.0)

  #  gl.drawmode {
  #    gl.threed {
  #      gl.draw_grid(20, 1.0)
  #      @cubes.each_with_index do |cube,i|
  #        cube.deltap(0, (i * 1.33) + 1.0, 0)
  #        cube.deltar(Math.cos((i+1)*-global_time), Math.sin((i+1) * global_time), 1.0, global_time * speed)
  #        #cube.deltar(0.5, 0, 1, global_time * speed)
  #        cube.draw(true)
  #      end
  #    }

  #    gl.twod {
  #      gl.button(25.0, 25.0, 33.0, 20.0, "login") {
  #        gl.emit({"c" => "tty"})
  #      }
  #    }
  #  }
  #}
#}

#sl.live(mab, render_todos, )

##
# 
# class BasicEntity
#   attr_accessor :speed, :cube
# 
#   def initialize(*args)
#     self.speed = 100.0
#     self.cube = Cube.new(*args)
#   end
# end
# 
# module BasicDrawing
#   def self.process(entity, global_time, delta_time)
#     entity.draw
#   end
# end
# 
# module BasicTransform
#   def self.process(entity, global_time, delta_time)
#     entity.deltar(Math.cos((entity.object_id) * -global_time), Math.sin((entity.object_id + 1) * global_time), 1.0, global_time * entity.speed)
#   end
# end
# 
# class ExampleSystem
#   attr_accessor :entities
# 
#   def initialize
#     super
# 
#     self.entities = []
#     self.entities << BasicEntity.new(0.13, 0.70, 0.15, 1.00)
#     self.entities << BasicEntity.new(0.17, 0.30, 0.90, 1.00)
#     self.entities << BasicEntity.new(1.10, 0.19, 0.40, 1.00)
#   end
# 
#   def process(manager)
#     self.entities.each { |entity|
#       manager.process(entity, BasicTransform, BasicDrawing)
#     }
#   end
# end

#module StaticFileServingSystem
#  include ServerSideSystem
#
#  static_files "public", "/"
#  static_files "public", "/nested"
#end

#module HtmlLiveView
#  server_side do
#    get "/" do
#    end
#  end
#end
#
#module DynamicBackendApi
#  server_side do
#    post "/api" do
#    end
#  end
#end
#
#module PubSubEvents
#  connected do
#    :open
#    :ok
#  end
#
#  disconnected do
#    :close
#    :ok
#  end
#
#  on "ping" do |from, msg|
#    send(from, "pong")
#
#    :ok
#  end
#
#  client_side do
#    connected do
#      :detected_server_accepted_connection
#
#      :allowed || :rejected
#
#      #@example = ExampleSystem.new
#      #run(@example)
#
#      :ok
#    end
#
#    disconnected do
#      :detected_server_gone_away
#
#      # reason
#
#      :ok
#    end
#  end
#
#  server_side do
#    connected do
#      :detected_client_desires_connection
#
#      # request
#
#      :allowed || :rejected
#    end
#
#    disconnected do
#      :detected_client_gone_away
#
#      :ok
#    end
#  end
#end
#
#module PingPongHeartbeat
#  every 30 do |global_time, delta_time|
#    #@manager.broadcast("ping")
#  end
#end
#
#module ServerSideLogic
#  server_side do
#    continuously do |global_time, delta_time|
#      log!(:server_side_continous_logic, global_time, delta_time)
#    end
#  end
#end
#
#module GraphicalUserInterface
#  client_side do
#    continuously do |global_time, delta_time|
#      #@manager.threed {
#      #  #@manager.lookat(1, 11.0, 7.0, 13.0, 0.0, 0.0, 0.01, 15.0)
#      #}
#      ##@manager.twod {
#      ##  @manager.button(50.0, 50.0, 250.0, 20.0, "login test #{'%0.2f' % global_time}") {
#      ##    @mananger.emit({"c" => "tty"})
#      ##  }
#      ##}
#    end
#  end
#end

#include StaticFileServing

#include HtmlLiveView
#include DynamicBackendApi
#include GraphicalUserInterface
#include PubSubEvents

#@foos ||= []
#
#module ProllyNestedMod
#end
#
#class ProllyNestedClass
#  def cheese
#  end
#end
#
#module ::MyModule
#end
#
#class ::MyClass
#end
#
#@foos << ProllyNestedClass.new
#
#log!(:self, Wkndr, self, ::MyModule, ::MyClass, ProllyNestedMod, ProllyNestedClass)
#log!(@foos.object_id, @foos)
#
#@foos[0].cheese

##  this is wkndr
#
##  sl.live_index { |conn|
##    #LiveView.Controller.live_render(conn, MyAppWeb.GithubDeployView, session: %{})
##  }
##
##  render_todos = lambda { |assigns|
##
##    mab = Markaby::Builder.new
##    mab.ul do
##      assigns[:todos].each { |todo|
##        mab.li todo
##      }
##    end
##    mab.to_s
##  end
##
##  def mount(socket)
##    :ok, Wkndr.assign(socket, {:todos => []})
##  end
##
##	sl.handle_event("github_deploy", _value, socket) do
##  # do the deploy process
##  {:noreply, assign(socket, deploy_step: "Starting deploy...")}
##end
##  def mount(%{id: id, current_user_id: user_id}, socket) do
##    if connected?(socket), do: :timer.send_interval(30000, self(), :update)
##
##    case Thermostat.get_user_reading(user_id, id) do
##      {:ok, temperature} ->
##        {:ok, assign(socket, temperature: temperature, id: id)}
##
##      {:error, reason} ->
##        {:error, reason}
##    end
##  end
##
##  def handle_info(:update, socket) do
##    {:ok, temperature} = Thermostat.get_reading(socket.assigns.id)
##    {:noreply, assign(socket, :temperature, temperature)}
##  end
## LiveView is first rendered statically as part of regular HTTP requests, which provides quick times for "First Meaningful Paint" and also help search and indexing engines;
## All of the data in a LiveView is stored in the socket as assigns. 
## live_render socket, MyLiveView, container: {:tr, class: "highlight"}
## <button wkndr-click="inc_temperature">+</button>
## Params	phx-value-*
## Click Events	phx-click
## Focus/Blur Events	phx-blur, phx-focus, phx-target
## Form Events	phx-change, phx-submit, data-phx-error-for, phx-disable-with
## Key Events	phx-keydown, phx-keyup, phx-target
## Rate Limiting	phx-debounce, phx-throttle
## Custom DOM Patching	phx-update
## JS Interop	phx-hook
##Any number of optional phx-value- prefixed attributes, such as:
##
##<div phx-click="inc" phx-value-myvar1="val1" phx-value-myvar2="val2">
##
##will send the following map of params to the server:
##
##def handle_event("inc", %{"myvar1" => "val1", "myvar2" => "val2"}, socket) do
##def error_tag(form, field) do
##  Enum.map(Keyword.get_values(form.errors, field), fn error ->
##    content_tag(:span, translate_error(error),
##      class: "help-block",
##      data: [phx_error_for: input_id(form, field)]
##    )
##  end)
##end
##def render(assigns) ...
##
##def mount(_session, socket) do
##  {:ok, assign(socket, %{changeset: Accounts.change_user(%User{})})}
##end
##
##def handle_event("validate", %{"user" => params}, socket) do
##  changeset =
##    %User{}
##    |> Accounts.change_user(params)
##    |> Map.put(:action, :insert)
##
##  {:noreply, assign(socket, changeset: changeset)}
##end
##
##def handle_event("save", %{"user" => user_params}, socket) do
##  case Accounts.create_user(user_params) do
##    {:ok, user} ->
##      {:stop,
##       socket
##       |> put_flash(:info, "user created")
##       |> redirect(to: Routes.user_path(AppWeb.Endpoint, AppWeb.User.ShowView, user))}
##
##    {:error, %Ecto.Changeset{} = changeset} ->
##      {:noreply, assign(socket, changeset: changeset)}
##  end
##end
#
#class TodoLive
#  def index
#  end
#
#### ??? handle_call(msg, from, socket)
#### ??? terminate(reason, socket)
###handle_event(event, unsigned_params, socket) # from client
###handle_info(msg, socket) # like handle event, but from internal event source
###handle_params(unsigned_params, uri, socket) # from internal re-routing of queryString params, like sort filter
###mount(session, socket)
###render(assigns)
#
#end
#
#
#Wkndr.camp { |sl|
#	
#
#  sl.get('/bloops') { |ids_from_path|
#	}
#
#  sl.get('/todos') { |ids_from_path|
#    mab = Markaby::Builder.new
#    mab.html5 {
#      mab.head { mab.title "TODOS" }
#      mab.body {
#        mab.h1 "TODOS"
#        sl.live(mab, render_todos, )
#      }
#    }
#    bytes_to_return = mab.to_s
#  }
#
#  sl.get('/boats') { |ids_from_path|
#    mab = Markaby::Builder.new
#    mab.html5 do
#      mab.head { mab.title "Boats.com" }
#      mab.body do
#        mab.h1 "Boats.com has great deals"
#        mab.ul do
#          mab.li "$2.99 for a canoe"
#          mab.li "$3.99 for a raft"
#          mab.li "$4.99 for a huge boat that floats and can fit 5 people"
#        end
#      end
#    end
#    bytes_to_return = mab.to_s
#  }
#}
#
#Wkndr.play { |gl|
#  gl.lookat(1, 11.0, 7.0, 13.0, 0.0, 0.0, 0.01, 15.0)
#
#  total_msg = 0
#
#  cubes = []
#  cubes << Cube.new(0.13, 0.70, 0.15, 1.00)
#  cubes << Cube.new(0.17, 0.30, 0.90, 1.00)
#  cubes << Cube.new(1.10, 0.19, 0.40, 1.00)
#
#  gl.event { |typed_msg|
#    total_msg += 1
#  }
#
#  gl.update { |global_time, delta_time|
#    speed = 100.0 # + (global_time * 10.0)
#
#    gl.drawmode {
#      gl.threed {
#        cubes.each_with_index do |cube,i|
#          cube.deltar(Math.cos((i+1)*-global_time), Math.sin((i+1) * global_time), 1.0, global_time * speed)
#          #cube.deltar(0.5, 0, 1, global_time * speed)
#          cube.draw(true)
#        end
#      }
#
#      gl.twod {
#        gl.button(50.0, 50.0, 250.0, 20.0, "login test #{total_msg}/#{'%0.2f' % global_time}") {
#          gl.emit({"c" => "tty"})
#        }
#      }
#    }
#  }
#}
#
##Implementation
##Concepts
##
##    Entity: An integer.
##    Entity Manager: A singleton class.
##    Component: A class with data.
##    System: A generic class with methods and an object array.
##    Component System: A singleton class that extends System using a specific Component class.
##
##Duties
##
##    Entity: A handle shared by all systems. It has no idea what components it has.
##    Entity Manager: Prevents duplicate IDs from being handed out. Recycles IDs that have been removed from all component systems. Handles the removal of an entity from all component systems.
##    Component: Holds data of a specific type. If things get dirty (as rapid game development often does), it can have methods for other systems to work with that data, such as a vector class that can return its magnitude.
##    System: (This is a generic class, and never used directly) Manage an array of Components of a specified class, using the value of Entity as an index. Has methods to add, update, get, remove, and process that data.
##    Component System: Extends System with the Component's class. Almost always overrides the Process function.
##
##Expansion
##
##Out of the box, it is only possible to process (or try to process) every object, in every system, each frame. But the framework also allows a system to process individual entities. This could lead to a "group" class that manages its own list of entity ID's, preventing wasted cycles on "blank" entries in systems. It would still use the Entity Manager to create and destroy entities.
##
##
#
# Components in GameEcs are ordinary Ruby classes. In most cases, they should be struct-like classes with attr_accessor properties only. Adding default values in the constructor is as advanced as these objects should get.
#
# An Entity is simply a collection of Components joined together by an id. To create one, simply call the add_entity method with a list of the Components you want the Entity to initially have:
#
#
# The great thing about ECS is the ability to add/remove components at runtime. Here's how to do it:

#  # add a Color component
#  store.add_component(id: ent_id, component: Color.new(red: 255, green: 255, blue: 0))
#  
#  # we remove by class
#  store.remove_component(id: ent_id, klass: Color)
#  
#  # remove an entire entity
#  store.remove_entity(id: ent_id)
#  
#  # remove many entities
#  store.remove_entities(ids: list_of_ids)
#  
# 
#  Querying by Components
# GameEcs has a Query class that can be used for more advanced queries, but the most common case is that you want all enitities that have all the components you're interested in. musts is short had for building these types of queries:
# 
# ents_that_need_move = store.musts(Position, Velocity)
# ents_that_need_move.each do |ent|
#   pos,vel = ent.components
#   # modify pos based on vel
# end
# 
## store.each_entity(Position, Velocity) do |ent|
#  pos,vel = ent.components
#  # modify pos based on vel
#end
#
#  class Game
#    def intialize
#      @store = GameEcs::EntityStore.new
#      @render_system = RenderSystem.new(@store)
#      @systems = [
#        MovementSystem.new(@store),
#        # .. other systems
#        @render_system
#      ]
#    end
#  
#    def update(time_delta, inputs)
#      @systems.each{|sys| sys.update(time_delta, inputs) }
#    end
#  
#    def draw
#      @render_system.render
#    end
#  end
#  
#  class MovementSystem
#    def initialize(store)
#      @store = store
#    end
#  
#    def update(dt, inputs)
#      @store.each_entity(Position, Velocity) do |ent|
#        pos,vel = ent.components
#        pos.x += vel.x * dt
#        pos.y += vel.y * dt
#      end
#    end
#  end

#  # So far I know that an Entity should be pretty barebones. A collection of components and possibly a transform component since it'll be so common. Probably an unique ID and/or name too.
#  
#  Components should be pure data, no logic. A renderable component could contain a mesh and material for example.
#  
#  Systems do the work and act on entities which meet their requirements. So a physics system will work on entities which have a physics component. A enemy soldier controller system will act on entities which have an enemy and soldier component.
#  
#  
#  The EntityManager is a class that governs the EC system. It is the fundamental kernel of EC. Its responsibilities include:
#  
#      Create and kill entities
#      Maintain a list of all known entities
#      Map entities to their components
#      Retrieve entities’ component functionality on demand
#  
# # Philosophically speaking, how do we define components? What should they be?
# 
# A component should encapsulate the data necessary to drive a behavior, an aspect, or a feature of the entity who owns it. Remember, we’re striving for composition over inheritance, so ask yourself: what are the things that the entity in question is composed of?
# 
# In this blog post series we are working our way toward a “Lunar Lander” type game. So let’s begin by thinking about our lander entity. What are some of the behaviors or features it should have? What is a lander composed of?
# 
#     It should be sensitive to gravity
#     It should have an engine
#     It needs fuel to burn in the engine
#     It needs an X-Y position
#     It needs a graphic to render
#     It needs to have velocity
# 
# # class Fuel < Component
#   attr_accessor :remaining
#  
#   def initialize(remaining)
#     super()
#     @remaining=remaining
#   end
#  
#   def burn(qty)
#     @remaining -= qty
#     @remaining = 0 if @remaining < 0
#   end
# end

# tank_entity = @entity_manager.create_tagged_entity(‘blue_side’)
# @entity_manager.add_component(tank_entity, WorldPosition.new(45.123,–123.234))
#  
# air_entity = @entity_manager.create_tagged_entity(‘red_side’)
# @entity_manager.add_component(air_entity, WorldPosition.new(47.5,–121.3))
# @entity_manager.add_component(air_entity, Flight.new(3000))

# class EngineSystem < System
#   def process_one_game_tick(delta, entity_mgr)
# 	end
# end

# ########
# #
# # ClientSide / FarSide / LightSide / ExploreSide / PlaySide / WindowSide
# #   sandboxed mruby context, minimal dependencies, NO SYSTEM INTERFACE
# #
# #
# # WindowSide
# # EtlSide
# #  shape of data?
# #
# # ServerSide / NearSide / HeavySide / CampSide / BuildSide / WindowSide
# #   full raw mruby context, all deps for all project, includes several system interfaces
# #   libuv
# #   Thread
# #   IO
# #
# 
# #
# # LiveView
# #   GET
# #   MOUNT
# #   RENDER
# #   CONNECT
# #   STATE
```
              when "c"
                dispatch_req = typed_msg[channel]
                if dispatch_req == "tty" #TODO: remove tty integration!!!
                  unless @ps
                    @ftty = FastTTY.fd

                    #log!(:FTTY, @ftty)

                    @stdin_tty = UV::Pipe.new(false)
                    @stdin_tty.open(@ftty[0])

                    #= UV::Pipe.new(false)

                    @stdout_tty = UV::Pipe.new(false)
                    @stdout_tty.open(@ftty[1])

                    #@pid = @ftty[2].gsub("/dev/", "")
                    
                    #Process_args = {
                    #  #'stdio' => [@ftty[1], @ftty[1], @ftty[1]],
                    #  #'file' => '/usr/bin/ruby',
                    #  #'args' => ['/var/lib/wkndr/Thorfile', 'getty', @pid],
                    #  'file' => '/sbin/agetty',
                    #  'args' => [
                    #    "--timeout", "30",
                    #    "--login-program", 
                    #    "/usr/bin/ruby", 
                    #    "--login-options", 
                    #    "/var/lib/wkndr/exgetty.rb login -- \\u", 
                    #    "115200", "-", "xterm-256color"],
                    #  'detached' => true,
                    #  'env' => []
                    #}

                    process_args = {
                      'stdio' => [@ftty[1], @ftty[1], @ftty[1]],
                      #'file' => '/usr/bin/top',
                      'file' => '/usr/bin/htop',
                      #'file' => '/bin/dash',
                      #'file' => '/bin/ls',
                      'detached' => true,
                      #'args' => ["-i"]
                      'args' => []
                    }

                    #log!(:args, process_args)

                    @ps = UV::Process.new(process_args)

                    #log!(:PROCESS_NEW)

                    #@ps.stdin_pipe = UV::Pipe.new(false)
                    #@ps.stdout_pipe = UV::Pipe.new(false)
                    #@ps.stderr_pipe = UV::Pipe.new(false)

                    #@ps.stdin_pipe = @stdin_tty 
                    #@ps.stdout_pipe = @stdout_tty
                    #@ps.stderr_pipe = @stdout_tty

                    #log!(:ASSIGN)

                    #@ps.stdin_pipe.open(@ftty[0])
                    #@ps.stdout_pipe.open(@ftty[1])

                    @ps.spawn do |sig|
                      #log!(:ps_spawn_exit, "exitsig #{sig}")

                      @pid = nil
                      @ps = nil
                    end

                    #log!(:SPAWN)

                    #outbits = {1 => "FART FART FART"}
                    #self.write_typed(outbits)

                    #@stdin_tty.read_start do |bout|
                    #@ps.stdout_pipe.read_start do |bout|
                    #@ps.stdout_pipe.read_start do |bout|
                    @stdin_tty.read_start do |bout|
                    #@stdin_tty.read_start do |bout|
                      #log!(:stdin_tty, bout)

                      if bout.is_a?(UVError)
                        #log!(:badout, bout)
                      elsif bout
                        outbits = {1 => bout}


                        self.write_typed(outbits)
                      end
                    end

                    #log!(:READ_A)

                    @stdout_tty.read_start do |bout|
                      #log!(:stderr_pipe, bout)
                    end

                    log!(:READ_B)

                    if @pending_resize
                      log!(:DORESIZE, @ps)
                      FastTTY.resize(@ftty[0], @pending_resize[0], @pending_resize[1])
                      #FastTTY.resize(@ps.stdin_pipe.fileno, @pending_resize[0], @pending_resize[1])
                      #@pending_resize = nil
                    end

                    @ps.kill(0)
                  else
                    log!(:ps_exists, @ps)
                    @ps.kill(0)
                  end
                end
