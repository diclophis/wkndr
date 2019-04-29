# #
# def log!(*args, &block)
#   $stdout.write(args.inspect)
#   $stdout.write("\n")
#   yield if block
# end
# 
# def spinlock!
# end

class ClientSide < Wkndr
  desc "server", ""
  def server
    log!(:clientserver_ignore)
  end
  method_added :server

  #def self.runblock!(stack)
  #  super(stack)

  #  while true
  #    self.block!
  #  end
  #end

  def self.wiz
    #log!(:self_client_stack, @client_stack)
    @client_stack.signal
  end
end

#ClientSide.startup(ARGV)

#client_side = ClientSide.start(ARGV)
#
