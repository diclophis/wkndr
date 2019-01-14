##

class PlatformBits

  ##def create_websocket_connection(&block)
  ##  ss = WslaySocketStream.new(self, block)
  ##  @all_connections << ss
  ##  ss.connect!
  ##  ss
  ##end

  #def log!(*args)
  #  #puts (args.inspect)
  #end

  #def puts!(*args)
  #  #puts(*args)
  #end

  #def spinlock!
  #  #puts :spinlock
  #end

  #def spindown!
  #  #puts :spindown
  #end
end

class PlatformSpecificBits < PlatformBits
end
