#

class ClientSide < Wkndr
  desc "client", ""
  def client(w = 512, h = 512)
    log!(:OUTERCLIENT_CLIENTSIDE_WH, w, h, self.class.to_s)

    stack = StackBlocker.new(false)

    self.class.open_client!(stack, w.to_i, h.to_i)

    stack
  end
  method_added :client

  desc "server", ""
  def server(*args)
    log!(:outerserver_on_clientside_ignore, args)

    nil
  end
  method_added :server

  def self.block!
    #log!(:clientside_block_bang_nowait_open)

    super

    UV.run(UV::UV_RUN_ONCE)

    i = UV::Idle.new
    #i.start {
    #}

    #t = UV::Timer.new
    #t.start(16, 0) do |x|
    #  #log!(:timer_clientside)
    #end

    #log!(:clientside_block_bang_nowait_close)

    true
  end
end
