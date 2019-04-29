#
def log!(*args, &block)
  $stdout.write(args.inspect)
  $stdout.write("\n")
  yield if block
end

def spinlock!
end

class ClientSide < Wkndr

  #default_command :client
end

#client_side = ClientSide.start(ARGV)
#Wkndr.update_with_timer!(client_side)
#
#while true
#  Wkndr.block!
#end
