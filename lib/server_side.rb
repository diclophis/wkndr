#

class ServerSide < Wkndr
  def self.install_trap!
    @keep_running = true

    UV::Signal.new.start(UV::Signal::SIGINT) do
      @keep_running = false
    end
  end

  def self.block!
    while @keep_running && foo = self.cheese_cross!
      super
      UV.run(UV::UV_RUN_NOWAIT)
    end

    log!(:exitfoooOOOO, @keep_running, foo)

    UV.run(UV::UV_RUN_NOWAIT)
    UV.default_loop.stop
  end
end
