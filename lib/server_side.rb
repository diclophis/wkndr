#

#class ServerSide < Wkndr
#  #desc "client", ""
#  #def client(w = 512, h = 512)
#  #  log!(:outerclient_serverside_ignore, w, h, self.class.to_s)
#  #  stack = StackBlocker.new(true)
#  #end
#  #method_added :client
#  def self.play(stack = nil, gl = nil, &block)
#    log!(:play_server_side, block, @stack, @gl)
#  end
#end

#server_side = ServerSide.start(ARGV)
#Wkndr.update_with_timer!(server_side)
