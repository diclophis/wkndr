#

def Integer(f)
  f.to_i
end

##TODO: move this somewhere
$stdout = UV::Pipe.new
$stdout.open(1)
$stdout.read_stop

def log!(*args, &block)
raise "wtf" if args.include?(:got_local_remote_c)

  $stdout.write(args.inspect + "\n") {
    yield if block
  }
end

log!(:argv, ARGV)

class Server
  def self.run!(directory)
    Server.new(directory)
  end

  def initialize(required_prefix)
    #TODO: where does this go????
    UV.disable_stdio_inheritance

    @all_connections = []
    @idents = -1

    @closing = false
    @closed = false

    UV::FS.realpath(required_prefix) { |resolved_prefix|
      @required_prefix = resolved_prefix

      host = '0.0.0.0'
      port = 8000
      @address = UV.ip4_addr(host, port)

      @server = UV::TCP.new
      @server.bind(@address)
      @server.listen(32) { |connection_error|
        self.on_connection(connection_error)
      }

      #s = UV::Pipe.new(true)
      #s.bind('/var/run/wkndr.sock')
      #s.listen(5) {|x|
      #  c = s.accept()
      #  read_from = c.read
      #  log!(:cread, read_from)
      #}

      update_utmp = Proc.new {
        utmp_file = "/var/run/utmp"
        @fsev = UV::FS::Event.new
        @fsev.start(utmp_file, 0) do |path, event|
          log!(:fswatch, path, event)
          if event == :change
            @fsev.stop

            #map ident???

            FastUTMP.idents.each { |pid, username|
              
            }

            update_utmp.call
          end
        end
      }
    }
  end

  def shutdown
    @all_connections.each { |cn|
      cn.shutdown
    }

    @server.close

    if @fsev
      @fsev.stop
      @fsev = nil
    end
  end

  def running
    !@halting
  end

  def halt!
    log!(:server_halt)
    @halting = @all_connections.all? { |cn| cn.halt! }
  end

  def on_connection(connection_error)
    if connection_error
      log!(:wtf_con_err, connection_error)
    else
      self.create_connection!
    end
  end

  def create_connection!
    @idents -= 1

    http = Connection.new(@server.accept, @idents, @required_prefix)

    @all_connections << http

    http.socket.read_start { |b|
      http.read_bytes_safely(b)
    }

    http
  end

  def signal
    self.update(0, 0)
  end

  def update(gt = nil, dt = nil)
    #NOOP: TODO????
  end
end
