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

  def self.server_side(cli, &block)
    if @server && block
      block.call(@server)

    end
  end

  def self.client_side(cli, &block)
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
    rescue NoMethodError => e
      e
    rescue LocalJumpError => e
      e
    rescue Timeout => e
      e
    rescue ScriptError => e
      e
    rescue Exception => e
      e
    rescue RuntimeError => e
      e
    end

    #TODO: better scripting isolation, 3rd mrb_context ????
    #rescue ScriptError => e
    #  log!(:FOO)
    #  log!(e)
    #  log!(e.inspect)
    #  log!(e.backtrace)
    #  e.inspect
    #rescue SyntaxError => e
    #  log!(:whazzzzz)
    #  log!(e)
    #  log!(e.inspect)
    #  log!(e.backtrace)
    #  e.inspect
    #rescue => e
    #  log!(:wha)
    #  log!(e)
    #  log!(e.inspect)
    #  log!(e.backtrace)
    #  e.inspect
    #end
  end

  def self.first_stack
    if @stacks_to_care_about
      @stacks_to_care_about[0]
    end
  end

  def self.wizbang!
    self.show!(self.first_stack)
  end

  def self.nonce(cli)
    @nonce ||= {}
    unless @nonce[cli]
      @nonce[cli] = true
      yield
    end
  end

  def self.run(klass)
    Wkndr.server_side(klass) { |gl, server|
    }
    Wkndr.client_side(klass) { |gl|
      gl.event(klass) { |channel, msg|
        klass.event(channel, msg)
      }

      gl.update(klass) { |global_time, delta_time|
        gl.drawmode {
          gl.threed {
            klass.draw_threed(gl)
            nil
          }
          gl.twod {
            klass.draw_twod(gl)

            nil
          }

          nil
        }

        klass.process_time(gl, global_time, delta_time)

        nil
      }
    }
  end

  #def self.timer(fps, &block)
  #  if block
  #    if fps < 0.0
  #      fps = 0.1
  #    end
  #    timer = UV::Timer.new
  #    fps = 1000.0/fps.to_f
  #    timer.start(fps, fps) do
  #      #log!(:wtf2, "foop timer")
  #      #TODO: timer.stop
  #      block.call
  #    end
  #  end
  #end

  #def initialize
  #  #@timeout = 0.0
  #end

  def self.xloop(name, fps = 60, &block)
    #air_thread = Fiber.new do |recycle_msg|
    #  while true
    #    recycle_msg = block.call(recycle_msg)
    #    recycle_msg = Fiber.yield(recycle_msg)
    #  end
    #end

    default_fps = fps.to_f
    default_timeout = (1.0 / default_fps)
    fibers_by_name[name] = {
      :last_fired => 0.0,
      :fps => default_fps,
      :block => block,
      :timeout => default_timeout,
      :recycle_msg => {:msg => :restart, :timeout => nil}
    }

    block
  end

  def self.xleap(recycle_msg) #, timeout = 0)
    Fiber.yield(recycle_msg) #{:msg => recycle_msg, :timeout => timeout})
  end

  def self.fibers_by_name
    $fibers_by_name ||= {}
    $fibers_by_name
  end

  def self.fiberz(gt = 0)
    #if @fibers_by_name

#Fiber.new do
      fibers_by_name.collect do |name, details|
      log! [name, details]

        details[:fiber] ||= Fiber.new do |recycle_msg|
          while true
            recycle_msg = details[:block].call(recycle_msg)
            recycle_msg = Fiber.yield(recycle_msg)
          end
        end

        #if (gt - details[:last_fired]) > details[:timeout]
  #raise "wtf #{name} #{self}"
          #delta = gt - details[:last_fired]

          #details[:recycle_msg].delete(:timeout)
          #details[:recycle_msg][:delta_time] = delta
#raise details[:fiber]
          recycle_msg = details[:fiber].resume(details[:recycle_msg])

          #if recycle_msg[:timeout]
          #  details[:timeout] = recycle_msg[:timeout]
          #else
          #  details[:timeout] = (1.0 / details[:fps])
          #end

          details[:recycle_msg] = recycle_msg

          #details[:last_fired] = gt
        #end
      end
#    #end
#end.resume
  end
end
