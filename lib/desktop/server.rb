#

class ProtocolServer
  def initialize(wkndrfile, host = '0.0.0.0', port = 8000)
    #TODO: where does this go????
    #UV.disable_stdio_inheritance

    @all_connections = []
    @idents = -1

    @closing = false
    @closed = false
    @handlers = {}

    subscribe_to_wkndrfile(wkndrfile)

    address = UV.ip4_addr(host, port)
    @server = UV::TCP.new
    @server.simultaneous_accepts = 4
    @server.bind(address)
    @server.listen(32) { |connection_error|
      log!(:on_connection, connection_error, self)

      create_connection(connection_error)
    }
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

  def create_connection(connection_error)
    if connection_error
      log!(:server_on_connection_connection_error, connection_error)
      return nil
    end

    begin
      @idents -= 1

      http = Connection.new(@server.accept)

      log!(:accepted, http)

      @all_connections << http

      http
    rescue => e
      log!(:create_connection_err, e)
      log!(e.backtrace)
      nil
    end
  end

  def signal
    self.update(0, 0)
  end

  def update(gt = nil, dt = nil)
    #NOOP: TODO????
    #log!(:tick)

    if @actual_wkndrfile && !@fsev
      log!(:rewatch)
      watch_wkndrfile
    end
  end

  #def get(path, &block)
  #  log!(:register_handler, path, block)
  #  tree = R3::Tree.new

  #  @handlers[path] = block

  #  @handlers.each { |k,v|
  #    tree.add(k, R3::ANY, v)
  #  }
  #  tree.compile

  #  @tree = tree
  #end

  #def match_dispatch(path)
  #  if @tree
  #    ids_from_path, handler = @tree.match(path)

  #    if ids_from_path && handler
  #      begin
  #        resp_from_handler = handler.call(ids_from_path)

  #        return Protocol.ok(resp_from_handler)
  #      rescue => e
  #        return Protocol.error(e.inspect)
  #      end
  #    end
  #  end
  #  
  #  return Protocol.missing
  #end

  #def block_accept
  #  @server.accept
  #end

  def subscribe_to_wkndrfile(wkndrfile_path = nil, write_back_connection = nil)
    wkparts = nil
    if wkndrfile_path
      wkparts = wkndrfile_path.split("~", 2)  
    end

    reqd_wkfile = "Wkndrfile"

    #if wkndrfile_path == nil #|| wkndrfile_path == "/" || (wkparts.length != 2)
    #else
    #  reqd_wkfile_user = wkparts[1].scan(/[a-z]/).join #TODO: better username support??
    #  reqd_wkfile = "/var/tmp/chroot/home/#{reqd_wkfile_user}/Wkndrfile"
    #end

    log!(:intend_subscribe_to_wkndrfile, reqd_wkfile, wkparts)


    UV::FS.realpath(reqd_wkfile) { |actual_wkndrfile|
      if actual_wkndrfile.is_a?(UVError)
        log!(:error_subscribe_to_wkndrfile_no_exists, actual_wkndrfile)
      else
        log!(:actual_subscribe_to_wkndrfile_full_real_path, self, reqd_wkfile, actual_wkndrfile)
        @actual_wkndrfile = actual_wkndrfile

        #watch_wkndrfile(actual_wkndrfile)
        #parse_wkndrfile.call(actual_wkndrfile, write_back_connection)
      end
    }
  end

  def watch_wkndrfile
    @fsev = UV::FS::Event.new
    @fsev.start(@actual_wkndrfile, 0) do |path, event|
      log!(:fsev, self, @fsev, path, event)

      if event == :change
        @fsev.stop

        parse_wkndrfile

        @fsev = nil
      end
    end
  end

  def parse_wkndrfile
    log!(:PARSEPARSE, @actual_wkndrfile)

    ffff = UV::FS::open(@actual_wkndrfile, UV::FS::O_RDONLY, UV::FS::S_IREAD)
    wkread = ffff.read(102400)

    did_parse = nil

    begin
      did_parse = Wkndr.wkndr_scoped_eval(wkread)
      #did_parse = Kernel.eval(wkread)
      #write_back_connection.write_typed({"party" => wkread}) if write_back_connection
    rescue => e
      log!(:outbound_party_parsed_bad, @actual_wkndrfile, e)
      log!(e.backtrace)
    end

    ffff.close

    did_parse
  end
end

#class Server
#  def self.run!(directory)
#    Server.new(directory)
#  end
#
#  def initialize(required_prefix)
#    #TODO: where does this go????
#    #UV.disable_stdio_inheritance
#
#    @all_connections = []
#    @idents = -1
#
#    @closing = false
#    @closed = false
#    @handlers = {}
#
#    update_utmp = Proc.new {
#      #osx
#      # utmp_file = "/var/run/utmpx"
#      #fake
#      # utmp_file = "/var/tmp/cheese"
#      #kube
#      utmp_file = "/var/run/utmp"
#      log!(:watch_utmp, utmp_file)
#
#      @fsev_utmp = UV::FS::Event.new
#      @fsev_utmp.start(utmp_file, 0) do |path, event|
#        if event == :change
#          @fsev_utmp.stop
#
#          connections_by_pid = {}
#          @all_connections.each { |cn|
#            if cn.pid
#              connections_by_pid[cn.pid] = cn
#            end
#          }
#
#          FastUTMP.utmps.each { |pts, username|
#            if fcn = connections_by_pid[pts]
#              logged_in_users_wkndrfile_path = ("~" + username)
#              subscribe_to_wkndrfile(logged_in_users_wkndrfile_path, fcn)
#            end
#          }
#
#          update_utmp.call
#        end
#      end
#    }
#
#    update_utmp.call
#
#    UV::FS.realpath(required_prefix) { |resolved_prefix|
#      if resolved_prefix.is_a?(UVError)
#        log!(:INITSERVER2ERR, required_prefix, resolved_prefix)
#      else
#        @required_prefix = resolved_prefix
#      end
#
#      host = '0.0.0.0'
#      port = 8000
#      @address = UV.ip4_addr(host, port)
#
#      @server = UV::TCP.new
#      @server.bind(@address)
#      @server.simultaneous_accepts = 4
#      @server.listen(32) { |connection_error|
#        self.on_connection(connection_error)
#      }
#    }
#  end
#
#  def shutdown
#    @all_connections.each { |cn|
#      cn.shutdown
#    }
#
#    @server.close
#
#    if @fsev
#      @fsev.stop
#      @fsev = nil
#    end
#
#    if @fsev_utmp
#      @fsev_utmp.stop
#      @fsev_utmp = nil
#    end
#  end
#
#  def running
#    !@halting
#  end
#
#  def halt!
#    @halting = @all_connections.all? { |cn| cn.halt! }
#  end
#
#  def on_connection(connection_error)
#    if connection_error
#      log!(:server_on_connection_connection_error, connection_error)
#    else
#      self.create_connection!
#    end
#  end
#
#  def create_connection!
#    @idents -= 1
#
#    http = Connection.new(self, @idents, @required_prefix)
#
#    @all_connections << http
#
#    http.socket.read_start { |b|
#      http.read_bytes_safely(b)
#    }
#
#    http
#  end
#
#  def signal
#    self.update(0, 0)
#  end
#
#  def update(gt = nil, dt = nil)
#    #NOOP: TODO????
#  end
#
#  def get(path, &block)
#    log!(:register_handler, path, block)
#    tree = R3::Tree.new
#
#    @handlers[path] = block
#
#    @handlers.each { |k,v|
#      tree.add(k, R3::ANY, v)
#    }
#    tree.compile
#
#    @tree = tree
#  end
#
#  def match_dispatch(path)
#    if @tree
#      ids_from_path, handler = @tree.match(path)
#
#      if ids_from_path && handler
#        begin
#          resp_from_handler = handler.call(ids_from_path)
#
#          return Protocol.ok(resp_from_handler)
#        rescue => e
#          return Protocol.error(e.inspect)
#        end
#      end
#    end
#    
#    return Protocol.missing
#  end
#
#  def block_accept
#    @server.accept
#  end
#
#  def subscribe_to_wkndrfile(wkndrfile_path, write_back_connection = nil)
#      wkparts = wkndrfile_path.split("~", 2)  
#
#      if wkndrfile_path == "/" || (wkparts.length != 2)
#        reqd_wkfile = "Wkndrfile"
#      else
#        reqd_wkfile_user = wkparts[1].scan(/[a-z]/).join #TODO: better username support??
#        reqd_wkfile = "/var/tmp/chroot/home/#{reqd_wkfile_user}/Wkndrfile"
#      end
#
#      log!(:intend_subscribe_to_wkndrfile, reqd_wkfile)
#
#      UV::FS.realpath(reqd_wkfile) { |actual_wkndrfile|
#        if actual_wkndrfile.is_a?(UVError)
#          log!(:error_subscribe_to_wkndrfile, actual_wkndrfile)
#        else
#          log!(:actual_subscribe_to_wkndrfile, wkndrfile_path, actual_wkndrfile)
#
#          ffff = UV::FS::open(actual_wkndrfile, UV::FS::O_RDONLY, UV::FS::S_IREAD)
#          wkread = ffff.read(102400)
#
#          begin
#            did_parse = Wkndr.wkndr_scoped_eval(wkread)
#            #did_parse = Kernel.eval(wkread)
#            write_back_connection.write_typed({"party" => wkread}) if write_back_connection
#          rescue => e
#            log!(:outbound_party_parsed_bad, e)
#            log!(e.backtrace)
#          end
#
#          ffff.close
#          @fsev = UV::FS::Event.new
#          @fsev.start(actual_wkndrfile, 0) do |path, event|
#            if event == :change
#              @fsev.stop
#              subscribe_to_wkndrfile(wkndrfile_path, write_back_connection)
#            end
#          end
#        end
#      }
#  end
#end
