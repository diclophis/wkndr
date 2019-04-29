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
  def server(*args)
    log!(:clientserver_ignore)
    stack = StackBlocker.new(false)
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
    if @client_stack
      @client_stack.signal
    end
  end

  def self.bang
   self.show!(@client_stack)
  end
end

#ClientSide.startup(ARGV)

#client_side = ClientSide.start(ARGV)
#
