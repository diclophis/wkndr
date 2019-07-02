#

def Integer(f)
  f.to_i
end

##TODO: move this somewhere
$stdout = UV::Pipe.new
$stdout.open(1)
$stdout.read_stop

def log!(*args, &block)
  $stdout.write(args.inspect + "\n") {
    yield if block
  }
end

def spinlock!
  $stdout.write("")
end

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
    @handlers = {}

    UV::FS.realpath(required_prefix) { |resolved_prefix|
      if resolved_prefix.is_a?(UVError)
        log!(:INITSERVER2ERR, required_prefix, resolved_prefix)
      else
        @required_prefix = resolved_prefix
      end

      host = '0.0.0.0'
      port = 8000
      @address = UV.ip4_addr(host, port)

      @server = UV::TCP.new
      @server.bind(@address)
      @server.listen(32) { |connection_error|
        self.on_connection(connection_error)
      }

      #update_utmp = Proc.new {
      #  #osx
      #  # utmp_file = "/var/run/utmpx"
      #  utmp_file = "/var/run/utmp"
      #  @fsev = UV::FS::Event.new
      #  @fsev.start(utmp_file, 0) do |path, event|
      #    if event == :change
      #      @fsev.stop

      #      connections_by_pid = {}
      #      @all_connections.each { |cn|
      #        if cn.pid
      #          connections_by_pid[cn.pid] = cn
      #        end
      #      }

      #      FastUTMP.utmps.each { |pts, username|
      #        if fcn = connections_by_pid[pts]
      #          logged_in_users_wkndrfile_path = ("~" + username)
      #          fcn.subscribe_to_wkndrfile(logged_in_users_wkndrfile_path)
      #        end
      #      }

      #      update_utmp.call
      #    end
      #  end
      #}

      #update_utmp.call
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
    @halting = @all_connections.all? { |cn| cn.halt! }
  end

  def on_connection(connection_error)
    if connection_error
      log!(:server_on_connection_connection_error, connection_error)
    else
      self.create_connection!
    end
  end

  def create_connection!
    @idents -= 1

    http = Connection.new(self, @idents, @required_prefix)

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

  def get(path, &block)
    log!(:register_handler, path, block)
    tree = R3::Tree.new

    @handlers[path] = block

    @handlers.each { |k,v|
      tree.add(k, R3::ANY, v)
    }
    tree.compile

    @tree = tree
  end

  def missing_response
    "HTTP/1.1 404 Not Found\r\nConnection: Close\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: 0\r\n\r\n"
  end

  def server_error(exception)
    "HTTP/1.1 500 Server Error\r\nConnection: Close\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: #{exception.length}\r\n\r\n#{exception}"
  end

  def match_dispatch(path)
    if @tree
      log!(:matching_routes, path, @tree.routes)
      ids_from_path, handler = @tree.match(path)
      if ids_from_path && handler
        begin
          mab = Markaby::Builder.new
          resp_from_handler = handler.call(ids_from_path, mab)
          bytes_to_return = mab.to_s
          "HTTP/1.1 200 OK\r\nConnection: Close\r\nContent-Length: #{bytes_to_return.length}\r\n\r\n#{bytes_to_return}"
        rescue => e
          log!(:html2, e)
          server_error(e.inspect)
        end
      else
        missing_response
      end
    end
  end

  def block_accept
    @server.accept
  end
end
