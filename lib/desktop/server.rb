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
    server = Server.new(directory)
  end

  def initialize(required_prefix)
    #TODO: where does this go????
    UV.disable_stdio_inheritance
    #required_prefix = "/home/jon/workspace/wkndr/public/"
    @required_prefix = required_prefix #"/var/lib/wkndr/public/"

    host = '0.0.0.0'
    port = 8000
    @address = UV.ip4_addr(host, port)

    @server = UV::TCP.new
    @server.bind(@address)
    @server.listen(32) { |connection_error|
      self.on_connection(connection_error)
    }

    @all_connections = []

    @closing = false
    @closed = false
  end

  def shutdown
    @all_connections.each { |cn|
      cn.shutdown
    }

    @server.close
  end

  def running
    !@halting
  end

  def halt!
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
    http = Connection.new(@server.accept, @required_prefix)

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
