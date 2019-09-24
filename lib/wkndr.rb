#
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

class Wkndr
  def self.runblock!(stack)
    self.update_with_timer!(stack)
  end

  def self.update_with_timer!(run_loop_blocker = nil)
    @stacks_to_care_about ||= []
    @stacks_to_care_about << run_loop_blocker
  end

  #def self.restartup(args_outer)
  #  #log!(:restartup, self.to_s, args_outer)
  #  stack = begin
  #    server_or_client_side = self.to_s
  #    
  #    case server_or_client_side
  #      when "ClientSide"
  #        client() #(*args_outer)
  #      when "ServerSide"
  #        server() #(*args_outer)
  #    end
  #  end
  #
  #  log!(:runblock!, self.to_s, args_outer, stack)
  #  runblock!(stack) if stack && stack.is_a?(StackBlocker) #TODO: fix odd start() dispatch case
  #end

  #def self.server_side
  #  server_or_client_side = self.class.to_s
  #  case server_or_client_side
  #    when "ClientSide"
  #      return nil
  #    when "ServerSide"
  #      yield
  #  end
  #end

  #def self.client_side
  #  server_or_client_side = self.class.to_s
  #  case server_or_client_side
  #    when "ClientSide"
  #      yield
  #    when "ServerSide"
  #      return nil
  #  end
  #end

  #def self.play(stack = nil, gl = nil, &block)
  #  # play is imp in ClientSide
  #end

  #def self.camp(&block)
  #  # camping is impl in ServerSide
  #end

  def self.play(stack = nil, gl = nil, &block)
    begin
      log!(:CHEEEESE, @stack, @gl)

      if block && !@stack && !@gl
        return
      end

      if @stack && @gl && block
        begin
          block.call(@gl)
        rescue => e
          log!(:e, e, e.backtrace)
          #@gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
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
    rescue => e
      log!(:einplay, e, e.backtrace)
    end
  end

  def self.camp(&block)
    log!(:server_side_camp, block, @server)
    return unless @server

    #TODO: abstrace base interface
    @server.get('/') { |ids_from_path|
      mab = Markaby::Builder.new
      mab.html5 "lang" => "en" do
        mab.head do
          mab.title "wkndr"
          mab.style do
            GIGAMOCK_TRANSFER_STATIC_WKNDR_CSS
          end
        end
        mab.body "id" => "wkndr-body" do
          mab.div "id" => "wkndr-terminal-container" do
            mab.div "id" => "wkndr-terminal", "class" => "maxwh" do
            end
          end
          mab.div "id" => "wkndr-graphics-container", "oncontextmenu" => "event.preventDefault()" do
            mab.canvas "id" => "canvas", "class" => "maxwh" do
            end
          end
          mab.script do
            GIGAMOCK_TRANSFER_STATIC_WKNDR_JS
          end
          mab.script "async" => "async", "src" => "wkndr.js" do
          end
        end
      end
      bytes_to_return = mab.to_s
    }

    @server.get('/robots.txt') { |ids_from_path|
      GIGAMOCK_TRANSFER_STATIC_ROBOTS_TXT
    }

    @server.get('/favicon.ico') { |ids_from_path|
      GIGAMOCK_TRANSFER_STATIC_FAVICON_ICO
    }

    block.call(@server)
  end

  def self.first_stack
    if @stacks_to_care_about
      @stacks_to_care_about[0]
    end
  end

  def self.set_stack(stack)
    @stack = stack
  end

  def self.set_gl(gl)
    @gl = gl
  end

  def self.set_server(server)
    @server = server
  end

  def self.the_server
    @server
  end

  def self.block!
    if @stacks_to_care_about
      running_stacks = @stacks_to_care_about.find_all { |rlb| rlb.running }

      if running_stacks.length > 0
        bb_ret = true
        running_stacks.each { |rlb| bb_ret = (bb_ret && rlb.cheese) }
        bb_ret
      else
        return true
      end
    else
      return true
    end
  end
end
