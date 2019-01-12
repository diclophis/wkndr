#

EMSDK_VERSION="1.38.21"

require_relative './mruby.rb'


MRuby::CrossBuild.new('emscripten') do |conf|
  # load specific toolchain settings
  toolchain :clang

  enable_debug

  conf.gem :core => "mruby-bin-mirb"
  conf.gem :core => "mruby-math"
  conf.gem :core => "mruby-random"
  conf.gem :core => "mruby-io"
  conf.gem :core => "mruby-enum-ext"
  conf.gem :core => "mruby-struct"

  conf.gem :github => "Asmod4n/mruby-simplemsgpack"

  conf.cc.command = "/root/emsdk/emscripten/#{EMSDK_VERSION}/emcc"
  conf.linker.command = "/root/emsdk/emscripten/#{EMSDK_VERSION}/emcc"
  conf.archiver.command = "/root/emsdk/emscripten/#{EMSDK_VERSION}/emar"
end
