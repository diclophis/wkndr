#

class ProtocolServer
  def initialize(safety_dir, host = '0.0.0.0', port = 8000)

    #TODO: where does this go????
    #UV.disable_stdio_inheritance

    @required_prefix = safety_dir

    @all_connections = []
    @clients_to_notify = {}

    @idents = -1

    @closing = false
    @closed = false
    @handlers = {}

    upgrade_to_binary_websocket_handler = Proc.new { |cn, phr, mab|
      cn.upgrade_to_websocket!
    }

    @handlers["/wsb"] = upgrade_to_binary_websocket_handler

    rebuild_tree!

    address = UV.ip4_addr(host, port)
    @server = UV::TCP.new
    @server.simultaneous_accepts = 4
    @server.bind(address)
    @server.listen(32) { |connection_error|
      #log!(:on_connection, connection_error, self)

      create_connection(connection_error)
    }

    subscribe_to_wkndrfile
  end

  def signal
    self.update(0, 0)
  end

  def update(gt = nil, dt = nil)
    #NOOP: TODO????
    #log!(:tick)

    if @actual_wkndrfile && !@fsev
      watch_wkndrfile
    end

    connections_to_drop = []

    @all_connections.each { |cn|
      if !cn.running?
        connections_to_drop << cn    
        log!(:should_drop, cn)
      else
        if cn.has_pending_request?
          request = cn.pop_request!
          response_from_handler = match_dispatch(cn, request)

          if response_from_handler == :upgrade || response_from_handler == :async
          elsif response_from_handler
            cn.write_response(response_from_handler)
          else
            cn.write_response(Protocol.empty)
          end
        end

        if cn.has_pending_parties?
          party = cn.pop_party!

          notify_client_of_new_wkndrfile(party, cn)

          wkread = read_wkndrfile 
          cn.write_typed({"party" => wkread})
        end
      end
    }

    connections_to_drop.each { |dcn|
      @all_connections.delete(dcn)
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

      #log!(:accepted, http)

      @all_connections << http

      http
    rescue => e
      log!(:create_connection_err, e)
      log!(e.backtrace)
      nil
    end
  end

  def raw(path, &block)
    log!(:register_handler, path, block)

    @handlers[path] = block

    rebuild_tree!
  end

  def live(path, title, &block)
    upgrade_to_websocket_handler = Proc.new { |cn, phr, mab|
      log!(:fooooows, cn, phr, mab)

      cn.add_subscription!(path, phr)
      cn.upgrade_to_websocket!
    }

    @handlers["/ws"] = upgrade_to_websocket_handler

    @all_connections.each { |cn|
      if phr = cn.subscribed_to?(path)
        inner_mab = Markaby::Builder.new
        inner_mab.div "id" => "wkndr-live-throwaway" do
          inner_mab_config = block.call(cn, phr, inner_mab)
        end
        next_inner_mab_bytes = inner_mab.to_s

        cn.write_text(next_inner_mab_bytes)
      end
    }

    handler = Proc.new { |cn, phr|
      inner_mab = Markaby::Builder.new
      inner_mab.div "id" => "wkndr-live-throwaway" do
        inner_mab_config = block.call(cn, phr, inner_mab)
      end
      initial_inner_mab_bytes = inner_mab.to_s

      mab = Markaby::Builder.new

      mab.html5 "lang" => "en" do
        mab.head do
          mab.title title
          #mab.style do
          #  GIGAMOCK_TRANSFER_STATIC_WKNDR_CSS
          #end
        end

        mab.body "id" => "wkndr-body" do
          mab.div "id" => "wkndr-terminal-container" do
            mab.div "id" => "wkndr-terminal", "class" => "maxwh" do
            end
          end

          mab.div "id" => "wkndr-live-container" do
            initial_inner_mab_bytes
          end

          mab.script do
            GIGAMOCK_TRANSFER_STATIC_WKNDR_JS
          end
        end
      end

      mab.to_s
    }

    @handlers[path] = handler

    rebuild_tree!
  end

  def wsb(path, &block)
    log!(:server_side_camp, block, self)
    #return unless @server

    #:#TODO: abstrace base interface
    raw('/') { |cn, ids_from_path|
      mab = Markaby::Builder.new
      mab.html5 "lang" => "en" do
        mab.head do
          mab.title "wkndr"
          mab.style do
            GIGAMOCK_TRANSFER_STATIC_WKNDR_CSS
          end
        end
        mab.body "id" => "wkndr-body" do
          mab.div "id" => "wkndr-terminal-container" do
            mab.div "id" => "wkndr-terminal", "class" => "maxwh" do
            end
          end
          mab.div "id" => "wkndr-graphics-container", "oncontextmenu" => "event.preventDefault()" do
            mab.canvas "id" => "canvas", "class" => "maxwh" do
            end
          end
          mab.script do
            GIGAMOCK_TRANSFER_STATIC_WKNDR_JS
          end
          mab.script "async" => "async", "src" => "wkndr.js" do
          end
        end
      end
      bytes_to_return = mab.to_s
    }

    raw(path + 'robots.txt') { |cn, ids_from_path|
      GIGAMOCK_TRANSFER_STATIC_ROBOTS_TXT
    }

    raw(path + 'favicon.ico') { |cn, ids_from_path|
      GIGAMOCK_TRANSFER_STATIC_FAVICON_ICO
    }

    @allow_static = true

    #block.call(@server) if block
  end

  def rebuild_tree!
    tree = R3::Tree.new

    @handlers.each { |k,v|
      tree.add(k, R3::ANY, v)
    }

    tree.compile

    @tree = tree
  end

  def match_dispatch(cn, request)
    if @tree
      ids_from_path, handler = @tree.match(request.path)

      if ids_from_path && handler
        begin
          resp_from_handler = handler.call(cn, ids_from_path)

          if resp_from_handler == :upgrade #|| response_from_handler == :async
            return resp_from_handler
          elsif resp_from_handler
            return Protocol.ok(resp_from_handler)
          end
        rescue => e
          return Protocol.error(e.inspect)
        end
      else
        requested_path = "#{@required_prefix}#{request.path}"
        #log!(:look_for, requested_path)

        UV::FS.realpath(requested_path) { |resolved_filename|
          if resolved_filename.is_a?(UVError) || !resolved_filename.start_with?(@required_prefix)
            log!(:hackz, resolved_filename)

            cn.halt!
          else
            cn.serve_static_file!(resolved_filename)
          end
        }

        return :async
      end
    end
    
    return Protocol.missing
  end

  def subscribe_to_wkndrfile(wkndrfile_path = nil)
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
    #log!(:intend_subscribe_to_wkndrfile, reqd_wkfile, wkparts)

    UV::FS.realpath(reqd_wkfile) { |actual_wkndrfile|
      if actual_wkndrfile.is_a?(UVError)
        log!(:error_subscribe_to_wkndrfile_no_exists, actual_wkndrfile)
      else
        log!(:actual_subscribe_to_wkndrfile_full_real_path, self, reqd_wkfile, actual_wkndrfile)
        @actual_wkndrfile = actual_wkndrfile
        @symbolic_wkndrfile = reqd_wkfile

        handle_wkndrfile_change
      end
    }
  end

  def watch_wkndrfile
    @fsev = UV::FS::Event.new
    @fsev.start(@actual_wkndrfile, 0) do |path, event|
      #log!(:fsev, self, @fsev, path, event)

      if event == :change
        @fsev.stop

        handle_wkndrfile_change

        @fsev = nil
      end
    end
  end

  def read_wkndrfile
    ffff = UV::FS::open(@actual_wkndrfile, UV::FS::O_RDONLY, UV::FS::S_IREAD)
    wkread = ffff.read(102400)
    ffff.close
    wkread
  end

  def notify_client_of_new_wkndrfile(wkndrfile, cn)
    @clients_to_notify[wkndrfile] ||= []
    @clients_to_notify[wkndrfile] << cn
  end

  def handle_wkndrfile_change
    wkread = read_wkndrfile 

    @clients_to_notify.each { |wkndrfile, clients|
      clients.each { |cn|
        cn.write_typed({"party" => wkread})
      }
    }

    did_parse = nil
    begin
      did_parse = Wkndr.wkndr_server_eval(wkread, self)
    rescue => e
     log!(:outbound_party_parsed_bad, @actual_wkndrfile, e)
     log!(e.backtrace)
    end

        #if write_back_connection
        #else
        #  parse_wkndrfile(wkread)
        #end
        #watch_wkndrfile(actual_wkndrfile)
        #parse_wkndrfile.call(actual_wkndrfile, write_back_connection)
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
