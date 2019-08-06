#

class Wkndr
  client_side do
    desc "client", ""
    def client(w = 512, h = 512)
    end
  end
end

# #
# 
# class ClientSide < Wkndr
#   desc "client", ""
#   def client(w = 512, h = 512)
#     stack = StackBlocker.new(false)
# 
#     self.class.open_client!(stack, w.to_i, h.to_i)
# 
#     stack
#   end
#   method_added :client
# 
#   desc "server", ""
#   def server(*args)
#     #log!(:outerserver_on_clientside_ignore, args)
# 
#     nil
#   end
#   method_added :server
# 
#   def self.block!
#     supblock = super
# 
#     UV.run(UV::UV_RUN_NOWAIT)
#   
#     UV.run(UV::UV_RUN_ONCE)
# 
#     supblock
#   end
# end
