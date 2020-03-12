class ProtocolServer
  def initialize(safety_dir, host = '0.0.0.0', port = 8000)

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
      create_connection(connection_error)
    }

    @async_place_holder = Proc.new { |requested_filename|
    }

    subscribe_to_wkndrfile
  end

  def update(gt = nil, dt = nil)
    if @actual_wkndrfile && !@fsev
      watch_wkndrfile
    end

    connections_to_drop = []

    if @clear_wkndrfile_change
      handle_wkndrfile_change
      @clear_wkndrfile_change = false
    end

    @all_connections.each { |cn|
      if !cn.running?
        connections_to_drop << cn    
      else
        if cn.has_pending_request?
          request = cn.pop_request!

          response = match_dispatch(cn, request)

          case response
            when String
              cn.write_response(response)

            when UV::Req

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

      @all_connections << http

      http
    rescue => e
      log!(:create_connection_err, e)
      log!(e.backtrace)
      nil
    end
  end

  def raw(path, &block)
    @handlers[path] = block

    rebuild_tree!
  end

  def live(path, title, &block)
    upgrade_to_websocket_handler = Proc.new { |cn, phr, mab|
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

      Protocol.ok(mab.to_s)
    }

    @handlers[path] = handler

    raw(path + 'robots.txt') { |cn, ids_from_path|
      Protocol.ok(GIGAMOCK_TRANSFER_STATIC_ROBOTS_TXT)
    }

    raw(path + 'favicon.ico') { |cn, ids_from_path|
      Protocol.ok(GIGAMOCK_TRANSFER_STATIC_FAVICON_ICO)
    }

    rebuild_tree!
  end

  def wsb(path, &block)
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
          resp_from_handler = handler.call(cn, ids_from_path)
          return (resp_from_handler)
      else
        requested_path = "#{@required_prefix}#{request.path}"

        xyz = UV::FS.realpath(requested_path, &handle_static_file(cn))

        return xyz
      end
    end
    
    return Protocol.missing
  end

  def handle_static_file(cn)
    Proc.new { |resolved_filename|
      if resolved_filename.is_a?(UVError) || !resolved_filename.start_with?(@required_prefix)
        cn.write_response(Protocol.missing)
      else
        cn.serve_static_file!(resolved_filename)
      end
    }
  end

  def subscribe_to_wkndrfile(wkndrfile_path = nil)
    wkparts = nil
    if wkndrfile_path
      wkparts = wkndrfile_path.split("~", 2)  
    end

    reqd_wkfile = "Wkndrfile"

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
    @fsev.start(@actual_wkndrfile, 1) do |path, event|
      if event == :change
        #handle_wkndrfile_change

        @clear_wkndrfile_change = true

        #@fsev = nil
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
      did_parse = Wkndr.wkndr_server_eval(wkread)
    rescue => e
     log!(:outbound_party_parsed_bad, @actual_wkndrfile, e)
     log!(e.backtrace)
    end
  end
end
