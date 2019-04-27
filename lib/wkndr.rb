#

class Wkndr < Thor
  def self.block!
  end

  #def self.play(stack = nil, gl = nil, &block)
  def self.play(stack = nil, gl = nil, &block)
    #log!(:play, stack, gl, block)
    #log!(:play)

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

    log!(:play, stack, gl, block, @stack, @gl)
    #[:play, nil, nil, #<Proc:0x558e97dc72d0>, nil, nil]

    if stack && !@stack
      @stack = stack
    end

    if gl && !@gl
      @gl = gl
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

    #if !block && @stack && @ql
    #  log!(:WTF_CASE_IS_THIS)
    #els

#[:where_is_at_gl, #<Proc:0x55f2bef9ec80>, #<GameLoop:0x55f2bea85b10 @pointer=#<Object:0x55f2bea85ae0>, @emit_proc=#<Proc:0x55f2bea855d0>, @play_proc=#<Proc:0x55f2bea84850>>]
#[:where_is_at_gl, #<GameLoop:0x55f2bea85b10 @pointer=#<Object:0x55f2bea85ae0>, @emit_proc=#<Proc:0x55f2bea855d0>, @play_proc=#<Proc:0x55f2bea84850>>]


    if block
      log!(:where_is_at_gl, block, @gl)

      @cheeses ||= []
      @cheeses << block

      @proc_foop = block
      @gl.update(&@proc_foop)
    end

    if @gl && @proc_foop
      log!(:where_is_at_gl, @gl)
      #[:where_is_at_gl, #<GameLoop:0x5624fc728b30 @pointer=#<Object:0x5624fc728b00>, @emit_proc=#<Proc:0x5624fc7285f0>, @play_proc=#<Proc:0x5624fc727870>>]

        begin
          @proc_foop.call(@gl)
          #@gl.update(&block)
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
    #else
    #  Wkndr.update_with_timer! @stack
    end
  end

  desc "server", ""
  def server(*args)
    Wkndr.start_server(*args)
  end

  def self.server(directory = "public")
    if File.exists?(directory)
      Server.run!(directory)
    end
  end

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

    if server = Wkndr.server
      stack.up(server)
    end

    stack
  end
end
