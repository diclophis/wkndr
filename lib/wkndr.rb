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

  def self.wkndr_server_eval(ruby_string)
    #ruby_string = "module Anon\n" + ruby_string + "\nend"

    eval(ruby_string)
  end

  def self.wkndr_client_eval(ruby_string)
    #ruby_string = "module Anon\n" + ruby_string + "\nend"

    #log!(:wtf, ruby_string)

    begin
      eval(ruby_string)
    rescue => e
      log!(e)
      log!(e.inspect)
      log!(e.backtrace)
      e.inspect
    end
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

  def self.run(klass)
    Wkndr.server_side { |gl, server|
      server.wsb("/")
    }

    Wkndr.client_side { |gl|
      gl.event { |channel, msg|
        klass.event(channel, msg)
      }

      gl.update { |global_time, delta_time|
        gl.drawmode {
          gl.threed {
            klass.draw_threed(gl)
          }
          gl.twod {
            klass.draw_twod(gl)
          }
        }

        klass.process_time(gl, global_time, delta_time)
      }
    }
  end

  def self.timer(fps, &block)
    if block
      if fps < 0.0
        fps = 0.1
      end

      timer = UV::Timer.new
      fps = 1000.0/fps.to_f
      timer.start(fps, fps) do
        #log!(:wtf2, "foop timer")
        #TODO: timer.stop
        block.call
      end
    end
  end
end
