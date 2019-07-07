#

class ClientSide < Wkndr
  #desc "server", ""
  #def server(*args)
  #  log!(:clientserver_ignore)
  #  stack = StackBlocker.new(false)
  #end

  desc "server", ""
  def server(*args)
    log!(:outerserver_on_clientside_ignore, args)
  end
  method_added :server
end
