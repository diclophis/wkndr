##

#TODO: figure out why this doesnt exist
def Integer(f)
  f.to_i
end

KEY_RIGHT = 262
KEY_LEFT = 263
KEY_DOWN = 264
KEY_UP = 265
KEY_A = 65
KEY_B = 66
KEY_C = 67
KEY_D = 68
KEY_E = 69
KEY_F = 70
KEY_G = 71
KEY_H = 72
KEY_I = 73
KEY_J = 74
KEY_K = 75
KEY_L = 76
KEY_M = 77
KEY_N = 78
KEY_O = 79
KEY_P = 80
KEY_Q = 81
KEY_R = 82
KEY_S = 83
KEY_T = 84
KEY_U = 85
KEY_V = 86
KEY_W = 87
KEY_X = 88
KEY_Y = 89
KEY_Z = 90

$cheese = "foo"

#def log!(*args, &block)
#  $cheese = args.inspect
#
#  if $stdout
#    $stdout.write(args.inspect)
#    $stdout.write("\n")
#  end
#
#  yield if block
#end

WKNDR_GLOBAL = true

class Timeout < Exception
end
