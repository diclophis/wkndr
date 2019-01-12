#

class SocketStream
  def disconnect!
  end

  def write(msg_typed)
    #begin
      #if @client
        #msg = MessagePack.pack(msg_typed)
        #@gl.log!(msg_typed, msg)
        #@client.queue_msg(msg, :binary_frame)
        #outg = @client.send
        #@gl.log!(outg)
        #outg
      #end
    #rescue Wslay::Err => e
    #  #@gl.log!(e)
    #end
  end
end
