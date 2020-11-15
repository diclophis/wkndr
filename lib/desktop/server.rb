#

class ProtocolServer
  def initialize(safety_dir, host = '0.0.0.0', port = 8000)
    @required_prefix = safety_dir

    @all_connections = []
    @clients_to_notify = {}
    @subscriptions = {}

    @idents = -1

    @closing = false
    @closed = false
    @handlers = {}

    upgrade_to_binary_websocket_handler = Proc.new { |cn, phr, mab|
      cn.upgrade_to_websocket! { |cn, channel, msg|
        unless channel == "party"
          @all_connections.each { |client|
            client.write_typed({channel => msg}) if (client.object_id != cn.object_id)
          }
        end
      }
    }

    @handlers["/wsb"] = upgrade_to_binary_websocket_handler

    upgrade_to_websocket_handler = Proc.new { |cn, phr, mab|
      cn.upgrade_to_websocket!
      #{ |cn, channel, msg|
      #  #TODO ????
      #  #@all_connections.each { |client|
      #  #  #client.write_typed({channel => msg}) if (client.object_id != cn.object_id)
      #  #}
      #}
    }
    @handlers["/ws"] = upgrade_to_websocket_handler

    #receive_http_post = Proc.new { |cn, phr, mab|
    #  raise "#{cn.phr.msg} #{cn.phr.headers} #{cn.phr.status}"
    #  #{ |cn, channel, msg|
    #  #  #TODO ????
    #  #  #@all_connections.each { |client|
    #  #  #  #client.write_typed({channel => msg}) if (client.object_id != cn.object_id)
    #  #  #}
    #  #}
    #}
    #@handlers["/inbox"] = receive_http_post
    #@handlers["/ws"] = upgrade_to_websocket_handler

    raw('/robots.txt') { |cn, ids_from_path|
      Protocol.ok(GIGAMOCK_TRANSFER_STATIC_ROBOTS_TXT)
    }

    raw('/favicon.ico') { |cn, ids_from_path|
      Protocol.ok(GIGAMOCK_TRANSFER_STATIC_FAVICON_ICO)
    }

    rebuild_tree!

    address = UV.ip4_addr(host, port)
    @server = UV::TCP.new
    @server.simultaneous_accepts = 4
    @server.bind(address)
    @server.listen(32) { |connection_error|
      create_connection(connection_error)
    }

    #@async_place_holder = Proc.new { |requested_filename|
    #}

    timer = UV::Timer.new
    timer.start(1000/60, 1000/60) do
      #unless @keep_running
        timer.stop
      #end
      #TODO: ?????? subscribe_to_wkndrfile
      wkread = read_wkndrfile("Wkndrfile") #TODO: #TODO:
      did_parse = Wkndr.wkndr_server_eval(wkread)
    end
  end

  def update(gt = nil, dt = nil, sw = 0, sh = 0)
    @gt = gt

    connections_to_drop = []

    watch_wkndrfiles

    #if @actual_wkndrfile && !@fsev
    ##elsif (@clear_wkndrfile_change != nil) && ((@gt - @clear_wkndrfile_change) > 1.0)
    ##  #@clear_wkndrfile_change
    ##  #&& ((Time.now.to_f - @clear_wkndrfile_change) > 0.1)
    ##  #@clear_wkndrfile_change -= dt
    ##  #if
    ##  raise "wtf"

    ##    handle_wkndrfile_change
    ##    #watch_wkndrfile
    ##    @clear_wkndrfile_change = nil
    ##    @fsev = nil
    #end

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
      #log!(:server_on_connection_connection_error, connection_error)

      return nil
    end

    begin
      @idents -= 1

      http = Connection.new(@server.accept)

      @all_connections << http

      http
    rescue => e
      #TODO: ???? is this halting ????
      #log!(:create_connection_err, e)
      #log!(e.backtrace)
      nil
    end
  end

  def raw(path, &block)
    @handlers[path] = block

    rebuild_tree!
  end

  def live(path, title, &block)
    initial_inner_mab_bytes = Proc.new { |cn, phr|
      inner_mab = Markaby::Builder.new
      inner_mab.div "class" => "wkndr-live-throwaway" do
        inner_mab_config = block.call(cn, phr, inner_mab)
      end
      inner_mab.to_s
    }

    #@all_connections.each { |cn|
    #  if phr = cn.subscribed_to?(path)
    #    cn.write_text(next_inner_mab_bytes.call(cn, phr))
    #  else
    #    raise "#{path} #{cn.get_subscriptions} #{@all_connections}"
    #  end
    #}

    if @handlers[path]
      @all_connections.each { |cn|
        ##if @subscriptions[path] && phr = @subscriptions[path][cn]
        ##if phr = cn.subscribed_to?(path)
          cn.write_text(JSON.dump({"foo" => initial_inner_mab_bytes.call(cn, {})}))
        #else

#lib/desktop/server.rb:186:in live: --- /sevengui --- #<Connection:0x557b969e3230> --- {} --- [#<Connection:0x557b969e3230 @socket=#<UV::TCP:0x557b969e3290>, @ss="", @last_buf="", @processing_handshake=true, @phr=#<Phr:0x557b969e3170>, @closing=false, @closed=false, @pending_requests=[], @pending_parties=[], @subscriptions={}>] --- {"/sevengui"=>{#<Connection:0x557b9691ef10 @socket=nil, @ss="GET /sevengui HTTP/1.1\r\nHost: localhost:8000\r\nUser-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:77.0) Gecko/20100101 Firefox/77.0\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\r\nAccept-Language: en-US,en;q=0.5\r\nAccept-Encoding: gzip, deflate\r\nDNT: 1\r\nConnection: keep-alive\r\nUpgrade-Insecure-Requests: 1\r\nCache-Control: max-age=0\r\n\r\n", @last_buf="", @processing_handshake=true, @phr=#<Phr:0x557b9691ee50>, @closing=false, @closed=false, @pending_requests=[], @pending_parties=[], @subscriptions={"/sevengui"=>{}}, @offset=375, @halting=true>=>{}}} (RuntimeError)

        #  raise "#{@all_connections} --- #{@subscriptions}" if @subscriptions.keys.length > 0
        #end
      }
    else
      handler = Proc.new { |cn, phr|
        #TODO: !!!!
        #cn.add_subscription!(path, phr)
        #@subscriptions[path] ||= {}
        #@subscriptions[path][cn] = phr

        #inner_mab = Markaby::Builder.new
        #inner_mab.div "id" => "wkndr-live-throwaway" do
        #  inner_mab_config = block.call(cn, phr, inner_mab)
        #end
        #initial_inner_mab_bytes = inner_mab.to_s

        mab = Markaby::Builder.new

        mab.html5 "lang" => "en" do
          mab.head do
            mab.title title
          end

          mab.body "id" => "wkndr-body" do
            #mab.div "id" => "wkndr-terminal-container" do
            #  mab.div "id" => "wkndr-terminal", "class" => "maxwh" do
            #  end
            #end

            mab.div "id" => "wkndr-live-#{title}", "class" => "wkndr-live-container" do
              initial_inner_mab_bytes.call(cn, phr)
            end

            mab.script do
              GIGAMOCK_TRANSFER_STATIC_BRIDGE_JS
            end
          end
        end

        Protocol.ok(mab.to_s)
      }

      @handlers[path] = handler

      rebuild_tree!
    end
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
            GIGAMOCK_TRANSFER_STATIC_BRIDGE_JS
          end
          mab.script "async" => "async", "src" => "wkndr.js" do
          end
        end
      end

      Protocol.ok(mab.to_s)
    }

    raw(path + 'robots.txt') { |cn, ids_from_path|
      Protocol.ok(GIGAMOCK_TRANSFER_STATIC_ROBOTS_TXT)
    }

    raw(path + 'favicon.ico') { |cn, ids_from_path|
      Protocol.ok(GIGAMOCK_TRANSFER_STATIC_FAVICON_ICO)
    }
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
#raise resolved_filename
      if resolved_filename.is_a?(UVError) || !resolved_filename.start_with?(@required_prefix)
        cn.write_response(Protocol.missing)
      else
        cn.serve_static_file!(resolved_filename)
      end
    }
  end

  #def subscribe_to_wkndrfile(wkndrfile_path)
  #  #wkparts = nil
  #  #if wkndrfile_path
  #  #  wkparts = wkndrfile_path.split("~", 2)  
  #  #end

  #  #reqd_wkfile = "Wkndrfile"
  #  reqd_wkfile = wkndrfile_path

  #  raise reqd_wkfile.inspect

  #  UV::FS.realpath(reqd_wkfile) { |actual_wkndrfile|
  #    if actual_wkndrfile.is_a?(UVError)
  #      #TODO: is this halting ??? !!!
  #      #log!(:error_subscribe_to_wkndrfile_no_exists, actual_wkndrfile)
  #    else
  #      #TODO: !!! log!(:actual_subscribe_to_wkndrfile_full_real_path, self, reqd_wkfile, actual_wkndrfile)

  #      raise actual_wkndrfile.inspect

  #      @actual_wkndrfile = actual_wkndrfile
  #      @symbolic_wkndrfile = reqd_wkfile
  #  
  #      handle_wkndrfile_change
  #    end
  #  }
  #end

  def watch_wkndrfiles
    #@fsev = UV::FS::Event.new
    #fsev_cb = Proc.new { |path, event|
    #  #log!(:wtf)
    #  #raise "Wtf #{@gt}"

    #  #if event == :change
    #    #@clear_wkndrfile_change = @gt
    #    handle_wkndrfile_change
    #    @fsev = nil
    #    #@fsev.start
    #    #@fsev.start(@actual_wkndrfile, 0)
    #  #end

    #}
    #
    #@fsev.start(@actual_wkndrfile, 0, &fsev_cb)
    
    #[wkndrfile] << cn
    @fsev ||= {}
    
    #wkndrfiles_to_watch = @clients_to_notify.keys
    @clients_to_notify.each { |wp, clients|
      unless @fsev[wp]
        fsev = UV::FS::Event.new
        fsev_cb = Proc.new { |path, event|
          handle_wkndrfile_change(wp, clients)
          @fsev.delete(wp)
        }
        fsev.start(wp, 0, &fsev_cb)
        @fsev[wp] = fsev
      end
    }
  end

  def read_wkndrfile(wp)
  #log!(:wtf2, @actual_wkndrfile)
    wkread = nil
    tries = 1024

begin
    ffff = UV::FS::open(wp, UV::FS::O_RDONLY, UV::FS::S_IREAD)
    wkread = ffff.read(1024000)
    ffff.close
rescue UVError => e
  tries -= 1
  retry unless tries < 0
  raise "#{tries} -- #{wp} -- #{e} #{self.inspect}"
end

    "srand(#{next_rand % 100000000 })\n" + wkread
  end

  def notify_client_of_new_wkndrfile(wkndrfile, cn)
    @clients_to_notify[wkndrfile] ||= []
    @clients_to_notify[wkndrfile] << cn
    handle_wkndrfile_change(wkndrfile, [cn])
  end

  def next_rand
    #@this_rand ||= 0
    #@this_rand += 1
    #@this_rand + Time.now.to_f
    Sysrandom.random
  end

  def handle_wkndrfile_change(wp, clients)
  #log!(:wtf_handle)

    wkread = read_wkndrfile(wp)

    clients.each { |cn|
      cn.write_typed({"party" => "$HEX='#{cn.hex}'\n" + wkread})
    }

    did_parse = nil
    #TODO: !!!! 
    #begin
#      did_parse = Wkndr.wkndr_server_eval(wkread)
    #rescue => e
    # #log!(:outbound_party_parsed_bad, @actual_wkndrfile, e)
    # #log!(e.backtrace)
    #end
  end

  def all_connections
    @all_connections
  end
end
