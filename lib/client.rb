#

stack = StackBlocker.new

gl = GameLoop.new(self)
stack.up(gl)

client = Wkndr.client(gl)
stack.up(client)

Wkndr.play(stack, gl)
