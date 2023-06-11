#

require_relative './vanilla.rb'

MRuby::CrossBuild.new('heavy') do |conf|
  ## load specific toolchain settings
  #toolchain :gcc

  conf.gem :core => "mruby-math"
  conf.gem :core => "mruby-random"
  conf.gem :core => "mruby-enum-ext"
  conf.gem :core => "mruby-struct"
  conf.gem :core => "mruby-metaprog"
  conf.gem :core => "mruby-sprintf"
  conf.gem :core => "mruby-string-ext"
  conf.gem :core => "mruby-eval"
  conf.gem :core => "mruby-pack"
  conf.gem :core => "mruby-set"

  # community provided gems
  conf.gem :github => "Asmod4n/mruby-b64", :branch => "master"
  conf.gem :github => "katzer/mruby-r3", :branch => "master"
  conf.gem :github => "diclophis/mruby-wslay", :branch => "fix-intended-return-of-exceptions-1.0" #TODO: get this merged with upstream https://github.com/tatsuhiro-t/wslay
  conf.gem :github => "Asmod4n/mruby-phr", :branch => "master"
  conf.gem :github => "Asmod4n/mruby-simplemsgpack", :branch => "master"
  conf.gem :github => "mattn/mruby-json", :branch => "master"

  conf.enable_debug

  conf.bins = []
  
  conf.cc do |cc|
    cc.flags = ["-O3", "-DMRB_NO_STDIO", "-DMRB_USE_DEBUG_HOOK"]
    #cc.flags = ["-O3", "-DMRB_UTF8_STRING"]

    #cc.flags = ["-O3", "-DMRB_METHOD_CACHE_SIZE=512", "-DMRB_GC_FIXED_ARENA", "-DMRB_INT64", "-DMRB_GC_ARENA_SIZE=10000"]
    #cc.flags = ["-O3", "-DMRB_METHOD_CACHE_SIZE=512", "-DMRB_GC_FIXED_ARENA", "-DMRB_GC_ARENA_SIZE=10000"]
    #cc.flags = ["-O0", "-DMRB_METHOD_CACHE_SIZE=512", "-DMRB_GC_FIXED_ARENA", "-DMRB_GC_ARENA_SIZE=10000"]
  end
end
