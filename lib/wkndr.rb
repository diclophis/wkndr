#

class Wkndr < Thor
  def self.first_stack
    if @stacks_to_care_about
      @stacks_to_care_about[0]
    end
  end

  def self.block!
    running_stacks = @stacks_to_care_about.find_all { |rlb| rlb.running }

    if running_stacks.length > 0
      bb_ret = true
      running_stacks.each { |rlb| bb_ret = (bb_ret && rlb.cheese) }
      bb_ret
    end
  end
  
  def self.runblock!(stack)
    self.update_with_timer!(stack)
  end

  def self.camp(&block)
    if @server
      log!(:server_side_camp, block, @server)
      block.call(@server)
    else
      log!(:client_side_skip)
    end
  end

  def self.set_stack(stack)
    @stack = stack
  end

  def self.set_server(server)
    @server = server
  end

  def self.the_server
    @server
  end

  def self.set_gl(gl)
    @gl = gl
  end

  def self.play(stack = nil, gl = nil, &block)
    log!(:play_client_side, block, @stack, @gl, @the_server)

    if block && !@stack && !@gl
      log!(:server_side_skip, Wkndr.the_server)
      return
    end

		if @stack && @gl && block
      begin
        block.call(@gl)
      rescue => e
        log!(:e, e, e.backtrace)
        @gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
        @gl.update { |global_time, delta_time|
          @gl.drawmode {
            @gl.threed {
            }
            @gl.twod {
              @gl.draw_fps(0, 0)
              @gl.button(50.0, 50.0, 250.0, 20.0, "error %s" % [e]) {
                @gl.emit({"c" => "tty"})
              }
            }
          }
        }
      end
		end

    if @gl && @stack
      @stack.cheese
    end
  end

  def self.start_server(stack, *args)
    log!(:StartServer)

    if server = self.server(*args)
      stack.up(server)
    end

    log!(:StartedServer)

    stack
  end

  def self.server(directory = "public")
    log!(:wtfclass, self, self.class)

    a_server = Server.run!(directory)
    Wkndr.set_server(a_server)
    a_server
  end

  desc "server", ""
  def server(*args)
    log!(:outerserver)

    stack = StackBlocker.new(true)

    self.class.start_server(stack, *args)

    stack
  end
  method_added :server

  def self.open_client!(stack, w, h)
    log!(:client, w, h, self.class.to_s)

    gl = GameLoop.new
    stack.up(gl)

    socket_stream = SocketStream.create_websocket_connection { |typed_msg|
      gl.event(typed_msg)
    }

    stack.did_connect {
      socket_stream.did_connect
    }

    stack.up(socket_stream)

    gl.emit { |msg|
      socket_stream.write(msg)
    }

    gl.open("wkndr", w, h, 61)

    gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
    gl.update { |global_time, delta_time|
      gl.drawmode {
        gl.threed {
        }
        gl.twod {
          #gl.draw_fps(0, 0)
          gl.button(50.0, 50.0, 250.0, 20.0, "zzz #{global_time} #{delta_time}") {
            gl.emit({"z" => "zzz"})
          }
        }
      }
    }

    Wkndr.set_stack(stack)
    Wkndr.set_gl(gl)
  end

  desc "client", ""
  def client(w = 512, h = 512)
    log!(:outerclient, w, h, self.class.to_s)

    stack = StackBlocker.new(false)

    self.class.open_client!(stack, w.to_i, h.to_i)

    stack
  end
  method_added :client

  def self.restartup(*args_outer)
    class_eval do
      desc "startup", ""
      def startup(*args)
        server_or_client_side = self.class.to_s

        case server_or_client_side
          when "ClientSide"
            client(*args)
          when "ServerSide"
            server(*args)
        end
      end
      method_added :startup
    
      default_command :startup
    end

    server_or_client_side = self.to_s

    case server_or_client_side
      when "ClientSide"
        stack = self.start(*args_outer)
        self.runblock!(stack)

      when "ServerSide"
        stack = self.start(*args_outer)
        self.runblock!(stack)
        #TODO: figure out why install trap needs to be here???
        #TODO: merge with runblock???
        self.install_trap!

    end
  end

  def self.update_with_timer!(run_loop_blocker = nil)
    @stacks_to_care_about ||= []
    @stacks_to_care_about << run_loop_blocker
  end

  def self.wizbang!
    self.show!(self.first_stack)
  end
end
