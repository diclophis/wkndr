#

class Wkndr < Thor
  def self.block!
    running_stacks = @stacks_to_care_about.find_all { |rlb| rlb.running }

    if running && running_stacks.length > 0
      log!(:wtf)

    #UV.run #(UV::UV_RUN_ONCE)
    #    #run_loop_blocker.cheese
      running_stacks.each { |rlb| rlb.cheese }
    end
  end
  
  def self.runblock!(stack)
    self.update_with_timer!(stack)
  end

  #def self.play(stack = nil, gl = nil, &block)
  def self.play(stack = nil, gl = nil, &block)
    #log!(:play, stack, gl, block)
    log!(:IMPL_play)

    #if stack && !@stack
    #  @stack = stack
    #end

    #if gl && !@gl
    #  @gl = gl
    #  gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
    #  gl.update { |global_time, delta_time|
    #    gl.drawmode {
    #      gl.threed {
    #      }
    #      gl.twod {
    #        gl.draw_fps(0, 0)
    #      }
    #    }
    #  }
    #end

    ##if !block && @stack && @ql
    #if block && @gl
    #  begin
    #    block.call(@gl)
    #  rescue => e
    #    #log!(:e, e, e.backtrace)
    #    @gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
    #    @gl.update { |global_time, delta_time|
    #      @gl.drawmode {
    #        @gl.threed {
    #        }
    #        @gl.twod {
    #          @gl.draw_fps(0, 0)
    #          @gl.button(50.0, 50.0, 250.0, 20.0, "error %s" % [e]) {
    #            @gl.emit({"c" => "tty"})
    #          }
    #        }
    #      }
    #    }
    #  end
    #else
    #  Wkndr.show! @stack
    #end
    #Wkndr.show!($stack)

    log!(:play, block, @stack, @gl)
    #[:play, nil, nil, #<Proc:0x558e97dc72d0>, nil, nil]

=begin
[:IMPL_play]  
[:play, #<Proc:0x556300cfebc0>, #<StackBlocker:0x556300d01f80 @for_server=false, @stack=[#<GameLoop:0x556300d01cb0 @pointer=#<Object:0x556300d01c80>, @emit_proc=#<Proc:0x556300d01770>>, #<WslaySocketStream:0x556300d01bc0 @got_bytes_block=#<Proc:0x556300d01c50>, @outbound_messages=[], @left_over_bits="", @last_buf="", @client=#<Wslay::Event::Context::Client:0x556300d019e0>, @phr=#<Phr:0x556300d019b0>, @host="127.0.0.1", @port=8000, @try_connect=#<Proc:0x556300d01860>, @t=#<UV::Timer:0x556300d01830>, @socket=#<UV::TCP:0x556300d00390>, @ss="HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: lFVjq5ajKy3rGuHvWTEVv8NnBqE=\r\n\r\n", @processing_handshake=false>], @fps=1, @did_connect_proc=#<Proc:0x556300d017a0>>, #<GameLoop:0x556300d01cb0 @pointer=#<Object:0x556300d01c80>, @emit_proc=#<Proc:0x556300d01770>>]
[:where_is_at_gl, #<Proc:0x556300cfebc0>, #<GameLoop:0x556300d01cb0 @pointer=#<Object:0x556300d01c80>, @emit_proc=#<Proc:0x556300d01770>>]
[:where_is_at_gl, #<GameLoop:0x556300d01cb0 @pointer=#<Object:0x556300d01c80>, @emit_proc=#<Proc:0x556300d01770>>]
=end


    if stack && !@stack
      @stack = stack
    end

		if @stack && @gl && block
			#@stack.update(&block)
      begin
        #@proc_foop.call(@gl)
        #@gl.update(&block)
        block.call(@gl)
      rescue => e
        log!(:e, e, e.backtrace)
        @gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
        @gl.update { |global_time, delta_time|
          @gl.drawmode {
            @gl.threed {
            }
            @gl.twod {
              @gl.draw_fps(0, 0)
              @gl.button(50.0, 50.0, 250.0, 20.0, "error %s" % [e]) {
                @gl.emit({"c" => "tty"})
              }
            }
          }
        }
      end
		end

    bizb = false
    if gl && !@gl
      @gl = gl
      bizb = true
    end

    if @gl && @stack
      @stack.cheese
    end

    if bizb
      gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
      gl.update { |global_time, delta_time|
        gl.drawmode {
          gl.threed {
          }
          gl.twod {
            gl.draw_fps(0, 0)
            gl.button(50.0, 50.0, 250.0, 20.0, "zzz #{global_time} #{delta_time}") {
              gl.emit({"z" => "zzz"})
            }
          }
        }
      }
    end

    #   #if !block && @stack && @ql
    #   #  log!(:WTF_CASE_IS_THIS)
    #   #els

#[:w#   here_is_at_gl, #<Proc:0x55f2bef9ec80>, #<GameLoop:0x55f2bea85b10 @pointer=#<Object:0x55f2bea85ae0>, @emit_proc=#<Proc:0x55f2bea855d0>, @play_proc=#<Proc:0x55f2bea84850>>]
#[:w#   here_is_at_gl, #<GameLoop:0x55f2bea85b10 @pointer=#<Object:0x55f2bea85ae0>, @emit_proc=#<Proc:0x55f2bea855d0>, @play_proc=#<Proc:0x55f2bea84850>>]

    #   if block
    #     log!(:where_is_at_gl, block, @gl)

    #     @cheeses ||= []
    #     @cheeses << block

    #     @proc_foop = block

    #     #@gl.update(&@proc_foop)
    #   end

    #   if @gl && @proc_foop
    #     log!(:where_is_at_gl, @gl)
    #     #[:where_is_at_gl, #<GameLoop:0x5624fc728b30 @pointer=#<Object:0x5624fc728b00>, @emit_proc=#<Proc:0x5624fc7285f0>, @play_proc=#<Proc:0x5624fc727870>>]

    #       begin
    #         #@proc_foop.call(@gl)
    #         #@gl.update(&block)
    #       rescue => e
    #         log!(:e, e, e.backtrace)
    #         @gl.lookat(0, 0.0, 500.0, 0.0, 0.0, 0.0, 0.01, 200.0)
    #         @gl.update { |global_time, delta_time|
    #           @gl.drawmode {
    #             @gl.threed {
    #             }
    #             @gl.twod {
    #               @gl.draw_fps(0, 0)
    #               @gl.button(50.0, 50.0, 250.0, 20.0, "error %s" % [e]) {
    #                 @gl.emit({"c" => "tty"})
    #               }
    #             }
    #           }
    #         }
    #       end
    #   #else
    #   #  Wkndr.update_with_timer! @stack
    #   end
  end

  #desc "server", ""
  #def server(*args)
  #  Wkndr.start_server(*args)
  #end

  desc "html", ""
  def html
    log!(:html)

    begin
      mab = Markaby::Builder.new

      mab.html5 do
        mab.head { mab.title "Boats.com" }
        mab.body do
          mab.h1 "Boats.com has great deals"
          mab.ul do
            mab.li "$49 for a canoe"
            mab.li "$39 for a raft"
            mab.li "$29 for a huge boot that floats and can fit 5 people"
          end
        end
      end
      #mab.div do
      #end
    rescue => e
      log!(:html2, e)
    end

    log!(mab.to_s)

    #stack = StackBlocker.new
    #stack.fps = 60

    #gl = GameLoop.new
    #stack.up(gl)

    #server = Wkndr.server
    #stack.up(server)

    #Wkndr.play(stack, gl)
  end
  method_added(:html) #TODO???

  #desc "something", ""
  #def something
  #  log!(:something)

  #  #stack = StackBlocker.new
  #  #stack.fps = 60

  #  #gl = GameLoop.new
  #  #$stack.up(gl)

  #  #client = Wkndr.client(gl)
  #  #$stack.up(client)

  #  #Wkndr.play(stack, gl)
  #end
  #method_added(:something) #TODO???

  def self.start_server(stack, *args)
    log!(:StartServer)

    if server = self.server
      stack.up(server)
    end

    log!(:StartedServer)

    stack
  end

  def self.server(directory = "public")
    log!(:wtfclass, self, self.class)

    if File.exists?(directory)
      Server.run!(directory)
    end
  end

  #def self.open_client!(stack, w, h)
  #  log!(:client, w, h)

  #  #stack = StackBlocker.new
  #  gl = GameLoop.new
  #  stack.up(gl)

  #  socket_stream = SocketStream.create_websocket_connection { |typed_msg|
  #    gl.event(typed_msg)
  #  }

  #  stack.did_connect {
  #    socket_stream.did_connect
  #  }

  #  stack.up(socket_stream)

  #  gl.emit { |msg|
  #    socket_stream.write(msg)
  #  }

  #  gl.open("wkndr", w, h, 120)

  #  #window.update { |gt, dt|
  #  #  gl.update(gt, dt)
  #  #}
  #  #stack.up(window)

  #  #stack.up(client)

  #  #stack
  #end

  desc "server", ""
  def server
    log!(:outerserver)

    stack = StackBlocker.new(true)
    ##stack.fps = 60

    self.class.start_server(stack)

    stack
  end
  method_added :server

  def self.open_client!(stack, w, h)
    log!(:client, w, h)

    #stack = StackBlocker.new
    gl = GameLoop.new
    stack.up(gl)

    socket_stream = SocketStream.create_websocket_connection { |typed_msg|
      gl.event(typed_msg)
    }

    stack.did_connect {
      socket_stream.did_connect
    }

    stack.up(socket_stream)

    gl.emit { |msg|
      socket_stream.write(msg)
    }

    gl.open("wkndr", w, h, 35)

    Wkndr.play(stack, gl)

    #window.update { |gt, dt|
    #  gl.update(gt, dt)
    #}
    #stack.up(window)

    #stack.up(client)

    #stack
  end

  desc "client", ""
  def client(w = 512, h = 512)
    log!(:outerclient, w, h)

    #client = Wkndr.client(w, h)
    stack = StackBlocker.new(false)
    #stack.fps = 60

    self.class.open_client!(stack, w.to_i, h.to_i)

    #Wkndr.play(stack, gl)
    stack
  end
  method_added :client

  #def startup(*args)
  ##  start(*args)
  #end
  #method_added :startup

  #default_command :startup

  def self.restartup(*args_outer)
    #$stdout.write("123")

    class_eval do
      #desc "startup", ""
      #def self.startup(*args)
      #  #self.start(*args)
      #end

      desc "startup", ""
      def startup(*args)
        #self.classstart(*args)
        #$stdout.write("startup#{self.class.to_s}")
        server_or_client_side = self.class.to_s

        case server_or_client_side
          when "ClientSide"
            client(*args)
          when "ServerSide"
            server(*args)
        end
      end
      method_added :startup
    
      default_command :startup
    end

    server_or_client_side = self.to_s

    case server_or_client_side
      when "ClientSide"
        stack = self.start(*args_outer)
        log!(:abc, stack)
        self.runblock!(stack)
        @client_stack = stack

      when "ServerSide"
        stack = self.start(*args_outer)
        log!(:efg, stack)
        self.runblock!(stack)
        while true
        begin
          self.cheese_cross!
        rescue => e
          log!(:eee, e)
        end

          self.block!
        end

    end
  end

  def self.update_with_timer!(run_loop_blocker = nil)
    log!(:install_timer, run_loop_blocker, run_loop_blocker.class)
    #$stdout.write([run_loop_blocker].inspect)

    @stacks_to_care_about ||= []
    @stacks_to_care_about << run_loop_blocker
  end
end
