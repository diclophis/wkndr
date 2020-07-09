#

#module Anon
#end

class Wkndr
  def self.runblock!(stack)
    self.update_with_timer!(stack)
  end

  def self.update_with_timer!(run_loop_blocker = nil)
    @stacks_to_care_about ||= []
    @stacks_to_care_about << run_loop_blocker
  end

  def self.server_side(&block)
    if @server && block
      block.call(@server)
    end
  end

  def self.client_side(&block)
    if @client && block
      block.call(@client)
    end

    #TODO: startup screen???
    #begin
    #  if block && !@stack && !@gl
    #    return
    #  end
    #  if @stack && @gl && block
    #    begin
    #      block.call(@gl)
    #    rescue => e
    #      log!(:e, e, e.backtrace)
    #      #@gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
    #      @gl.update { |global_time, delta_time|
    #        @gl.drawmode {
    #          @gl.threed {
    #          }
    #          @gl.twod {
    #            @gl.draw_fps(0, 0)
    #            @gl.button(50.0, 50.0, 250.0, 20.0, "error %s" % [e]) {
    #              @gl.emit({"c" => "tty"})
    #            }
    #          }
    #        }
    #      }
    #    end
    #  end
    #rescue => e
    #  log!(:einplay, e, e.backtrace)
    #end
  end

  def self.set_client(gl)
    @client = gl
  end

  def self.the_client
    @client
  end

  def self.set_server(server)
    @server = server
  end

  def self.the_server
    @server
  end

  def self.common_cheese_process!
    #log!(:wtf, @stacks_to_care_about)
    if @stacks_to_care_about
      running_stacks = @stacks_to_care_about.find_all { |rlb| rlb.running }
      if running_stacks.length > 0
        bb_ret = true
        running_stacks.each { |rlb| bb_ret = (bb_ret && rlb.signal) }
        bb_ret
      else
        return true
      end
    else
      return true
    end
  end

  def self.wkndr_server_eval(ruby_string)
    #ruby_string = "module Anon\n" + ruby_string + "\nend"

    eval(ruby_string)
  end

  def self.wkndr_client_eval(ruby_string)
    #ruby_string = "module Anon\n" + ruby_string + "\nend"

    eval(ruby_string)
  end

  def self.first_stack
    if @stacks_to_care_about
      @stacks_to_care_about[0]
    end
  end

  def self.wizbang!
    self.show!(self.first_stack)
  end

  def self.nonce
    unless @nonce
      @nonce = true
      yield
    end
  end
end
