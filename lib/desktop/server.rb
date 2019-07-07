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
      @server.simultaneous_accepts = 256
      @server.listen(512) { |connection_error|
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
    "HTTP/1.1 404 Not Found\r\nConnection: Close\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: 4\r\n\r\n404\n"
  end

  def server_error(exception)
    "HTTP/1.1 500 Server Error\r\nConnection: Close\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: #{exception.length}\r\n\r\n#{exception}"
  end

  def match_dispatch(path)
    if @tree
      ids_from_path, handler = @tree.match(path)
      #log!(:matching_routes, path, @tree.routes, handler, ids_from_path)

      if ids_from_path && handler
        begin
          mab = Markaby::Builder.new
          resp_from_handler = handler.call(ids_from_path, mab)
          bytes_to_return = mab.to_s

          "HTTP/1.1 200 OK\r\nConnection: Close\r\nContent-Length: #{bytes_to_return.length}\r\n\r\n#{bytes_to_return}"
        rescue => e
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

  def subscribe_to_wkndrfile(wkndrfile_path, write_back_connection = nil)
    log!(:subscribe_to_wkndrfile, wkndrfile_path)

    begin
      wkparts = wkndrfile_path.split("~", 2)  

      if wkndrfile_path == "/" || (wkparts.length != 2)
        reqd_wkfile = "Wkndrfile"
      else
        reqd_wkfile_user = wkparts[1].scan(/[a-z]/).join #TODO: better username support??
        reqd_wkfile = "/var/tmp/chroot/home/#{reqd_wkfile_user}/Wkndrfile"
      end

      UV::FS.realpath(reqd_wkfile) { |actual_wkndrfile|
        begin
          if actual_wkndrfile.is_a?(UVError)
            log!(:desktop_connection_wkndrfile_path_error, actual_wkndrfile)
          else
            log!(:subscribe_to_wkndrfile, wkndrfile_path, actual_wkndrfile)

            ffff = UV::FS::open(actual_wkndrfile, UV::FS::O_RDONLY, UV::FS::S_IREAD)
            wkread = ffff.read(102400)

            #log!(:ffff, ffff)
            #log!(:outgoing_wkndrfile, wkread.length, wkread)

            begin
              did_parse = Kernel.eval(wkread)
              #log!(:outbound_party_parsed_ok, did_parse)
              write_back_connection.write_typed({"party" => wkread}) if write_back_connection
            rescue => e
              log!(:outbound_party_parsed_bad, e)
            end

            ffff.close
            @fsev = UV::FS::Event.new
            @fsev.start(actual_wkndrfile, 0) do |path, event|
              if event == :change
                @fsev.stop
                subscribe_to_wkndrfile(wkndrfile_path, write_back_connection)
              end
            end
          end
        rescue => e
          log!(:desktop_server_wkndrfile_realpath_error, e, e.backtrace)
        end
      }
    rescue => e
      log!(:desktop_server_wkndrfile_subscribe_error, e, e.backtrace)
    end
  end
end
