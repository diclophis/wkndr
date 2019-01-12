#

class PlatformBits
  #def socket_klass
  #  SocketStream
  #end

  #def create_websocket_connection(&block)
  #  ss = socket_klass.new

  #  @websocket_singleton_proc = Proc.new { |bytes|
  #    yield bytes
  #  }

  #  ss
  #end

  ##def create_websocket_connection(&block)
  ##  ss = WslaySocketStream.new(self, block)
  ##  @all_connections << ss
  ##  ss.connect!
  ##  ss
  ##end

  def log!(*args)
    puts (args.inspect)
  end

  def puts!(*args)
    puts(*args)
  end

  def spinlock!
    puts :spinlock
  end

  def spindown!
    puts :spindown
  end
end

class PlatformSpecificBits < PlatformBits
end
