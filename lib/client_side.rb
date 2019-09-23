#

#TODO: refactor this!!
#class Wkndr
#  client_side do
#    desc "client", ""
#    def client(w = 512, h = 512)
#    end
#  end
#end

# #
# 
class ClientSide < Wkndr
  def self.client(w = 512, h = 512)
    stack = StackBlocker.new(false)

    self.open_client!(stack, w.to_i, h.to_i)

    stack
  end

  def self.server(*args)
    log!(:outerserver_on_clientside_ignore, args)

    nil
  end

  def self.block!
    supblock = super

    UV.run(UV::UV_RUN_NOWAIT)
  
    UV.run(UV::UV_RUN_ONCE)

    supblock
  end
end
