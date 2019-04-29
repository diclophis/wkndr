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
  def self.runblock!(stack)
    super(stack)

    while true
      self.block!
    end
  end
end

#ClientSide.startup(ARGV)

#client_side = ClientSide.start(ARGV)
#
