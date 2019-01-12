#

class PlatformSpecificBits < PlatformBits
  def initialize(*args)
    super(*args)

    #TODO: make stdin abstraction???
    @stdin = UV::Pipe.new
    @stdin.open(0)
    @stdin.read_stop

    #@stdin.read_start do |buf|
    #  if buf.is_a?(UVError)
    #    log!(buf)
    #  else
    #    if buf && buf.length
    #      self.feed_state!(buf)
    #    end
    #  end
    #end
    #self.init!

    @stdout = UV::Pipe.new
    @stdout.open(1)
    @stdout.read_stop

    @idle = UV::Timer.new
    @idle.start(0, 1) {
      self.update
    }

    @all_connections = []
  end

  def socket_klass
    WslaySocketStream
  end

  def create_websocket_connection(&block)
    ss = WslaySocketStream.new(self, block)
    @all_connections << ss
    ss.connect!
    ss
  end

  def log!(*args)
    @stdout.write(args.inspect + "\n") {
      false
    }
  end

  def spinlock!
    UV::run
  end

  def spindown!
    log! :spindown

    @idle.unref if @idle
    @stdin.unref if @stdin
    @stdout.unref if @stdout

    #tty = UV::TTY.new(0, 0)
    #tty.set_mode(1)
    #tty.reset_mode
    
    #@all_connections.each { |ss|
    #  ss.disconnect!
    #}
  end
end
