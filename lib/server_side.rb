#

class ServerSide < Wkndr
#  #desc "client", ""
#  #def client(w = 512, h = 512)
#  #  log!(:outerclient_serverside_ignore, w, h, self.class.to_s)
#  #  stack = StackBlocker.new(true)
#  #end
#  #method_added :client
#  def self.play(stack = nil, gl = nil, &block)
#    log!(:play_server_side, block, @stack, @gl)
#  end
        
  #def initialize(*args)
  #  #mruby/build/mrbgems/mruby-uv/example/tcp-server.rb

  #  super(*args)
  #end

  def self.install_trap!
    @keep_running = true

    UV::Signal.new.start(UV::Signal::SIGINT) do
      log!(:ctrlc)

      @keep_running = false

    #  #log!(:ctrlc)
    #  #self.class.first_stack.halt!
    #  #@server_stack = nil
    end
  end

  def self.wiz
    #begin
      while @keep_running && foo = self.cheese_cross!
        #log!(:foo, foo)
        self.block!

        UV.run(UV::UV_RUN_NOWAIT)
      end
      #log!(:halttted, @keep_running, foo)
    #rescue => e
    #  log!(e)
    #end
  end
end

#server_side = ServerSide.start(ARGV)
#Wkndr.update_with_timer!(server_side)
