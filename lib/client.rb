#

log!(:client)

stack = StackBlocker.new

gl = GameLoop.new(self)
stack.up(gl)

client = Wkndr.client(gl)
stack.up(client)

#Wkndr.start(["client", gl])
#block.call(gl)

Wkndr.play(stack, gl)
