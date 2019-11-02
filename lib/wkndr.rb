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
# #
# # LiveView
# #   GET
# #   MOUNT
# #   RENDER
# #   CONNECT
# #   STATE

class Wkndr
  def self.runblock!(stack)
    self.update_with_timer!(stack)
  end

  def self.update_with_timer!(run_loop_blocker = nil)
    @stacks_to_care_about ||= []
    @stacks_to_care_about << run_loop_blocker
  end

  def self.client_side(&block)
    begin
      log!(:start_client_side)

      if block && !@stack && !@gl
        log!(:skip_client_side)

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

  def self.set_stack(stack)
    @stack = stack
  end

  def self.the_stack
    @stack
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

  #def self.wkndr_scoped_eval(ruby_string, scopish)
  #  #module Foop
  #  #class_eval do
  #  #instance_eval do

  #    @scope = scopish

  #    #Wkndr.eval("module Anon\n" + ruby_string + "\nend")
  #    Kernel.eval(ruby_string)
  #  #end
  #end

  def self.wkndr_server_eval(ruby_string, scopish)
  #  #module Foop
  #  #class_eval do
  #  #instance_eval do

  #    @scope = scopish

  #    #Wkndr.eval("module Anon\n" + ruby_string + "\nend")
      self.set_server(scopish)

      Kernel.eval(ruby_string)
  #  #end
  end

  def self.registry
  end

  def self.server_side
    if @server
      yield @server
    end
  end

  def self.first_stack
    if @stacks_to_care_about
      @stacks_to_care_about[0]
    end
  end


  def self.wizbang!
    log!(:inwizbang, self.the_stack, self.first_stack, @stack, @stacks_to_care_about)

    self.show!(self.first_stack)
  end
end
