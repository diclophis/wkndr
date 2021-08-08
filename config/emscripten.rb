#

#EMSDK_VERSION="1.38.36"

require_relative './mruby.rb'


MRuby::CrossBuild.new('emscripten') do |conf|
  # load specific toolchain settings
  #toolchain :clang

  #enable_debug
  #conf.disable_cxx_exception

  #enable_debug
  conf.bins = []

  #conf.gem :core => "mruby-bin-mirb"
  conf.gem :core => "mruby-math"
  conf.gem :core => "mruby-random"
  conf.gem :core => "mruby-enum-ext"
  conf.gem :core => "mruby-struct"
  conf.gem :core => "mruby-metaprog"
  conf.gem :core => "mruby-sprintf"
  conf.gem :core => "mruby-string-ext"
  conf.gem :core => "mruby-eval"
  conf.gem :core => "mruby-pack"
  #conf.gem :core => "mruby-time"

  conf.gem :github => "yui-knk/mruby-set"
  conf.gem :github => "Asmod4n/mruby-simplemsgpack"
  #do |ff|
  #  ff.cc.defines = %w{MSGPACK_ENDIAN_LITTLE_BYTE=1 TEST_BIG_ENDIAN=0}
  #end
  
  #conf.gem :core => "mruby-io"

  ##conf.gem :github => "h2so5/mruby-pure-regexp"

  #conf.cc.command = "/root/emsdk/emscripten/#{EMSDK_VERSION}/emcc"
  #conf.linker.command = "/root/emsdk/emscripten/#{EMSDK_VERSION}/emcc"
  #conf.archiver.command = "/root/emsdk/emscripten/#{EMSDK_VERSION}/emar"

  #conf.cc.command = "/root/emsdk/fastcomp/emscripten/emcc"
  #conf.linker.command = "/root/emsdk/fastcomp/emscripten/emcc"
  #conf.archiver.command = "/root/emsdk/fastcomp/emscripten/emar"

  #conf.cc.defines = %w{MSGPACK_ENDIAN_LITTLE_BYTE=1 TEST_BIG_ENDIAN=0}

  conf.cc.command = "/root/emsdk/upstream/emscripten/emcc"
  conf.linker.command = "/root/emsdk/upstream/emscripten/emcc"
  conf.archiver.command = "/root/emsdk/upstream/emscripten/emar"

  #conf.enable_cxx_exception
  #conf.disable_cxx_exception

  conf.cc do |cc|
    #cc.defines << "MRB_USE_CXX_EXCEPTION=1"
    cc.flags = ["-s DISABLE_EXCEPTION_CATCHING=0", "-s USE_ZLIB=1", "-O3"] #, "-DMSGPACK_ENDIAN_LITTLE_BYTE=1", "-DTEST_BIG_ENDIAN=0"]
  end
end
