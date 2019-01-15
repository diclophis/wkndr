#

def Integer(f)
  f.to_i
end

$stdout.write("WTF")

##TODO: move this somewhere
$stdout = UV::Pipe.new
$stdout.open(1)
$stdout.read_stop

def log!(*args, &block)
  $stdout.write(args.inspect + "\n") {
    yield if block
  }
end

class Server
  def self.run!(directory)
    server = Server.new(directory)
  end

  def initialize(required_prefix)
    #TODO: where does this go????
    UV.disable_stdio_inheritance
    #required_prefix = "/home/jon/workspace/wkndr/public/"
    @required_prefix = required_prefix #"/var/lib/wkndr/public/"
    log!(:wtf, self, @required_prefix)

    host = '0.0.0.0'
    port = 8000
    @address = UV.ip4_addr(host, port)

    @server = UV::TCP.new
    @server.bind(@address)
    @server.listen(1) { |connection_error|
      self.on_connection(connection_error)
    }

    @all_connections = []

    @closing = false
    @closed = false
  end

  def shutdown
    log!(:server_shutdown)
    @all_connections.each { |cn|
      cn.shutdown
    }

    @server.close
  end

  def running
    !@halting
  end

  def halt!
    log!(:halt_server)
    @halting = @all_connections.all? { |cn| cn.halt! }
  end

  def on_connection(connection_error)
    if connection_error
      log!(connection_error)
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

  def update
    #NOOP: TODO????
  end

  def running_game
    nil
  end
end
