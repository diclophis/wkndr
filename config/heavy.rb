#

#class MRuby::Gem::LinkerConfig
#  def command
#    "g++"
#  end
#end

require_relative './vanilla.rb'

MRuby::CrossBuild.new('heavy') do |conf|
  # load specific toolchain settings
  toolchain :gcc

  # desired cli tooling
  #conf.bins = ["mrbc"]

  # core gems
  #conf.gem :core => "mruby-bin-mrbc"
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
  #conf.gem :core => "mruby-io"

  # community provided gems
  conf.gem :github => "Asmod4n/mruby-b64", :branch => "master"
  conf.gem :github => "yui-knk/mruby-set", :branch => "master"
  conf.gem :github => "iij/mruby-zlib", :branch => "master"
  conf.gem :github => "katzer/mruby-r3", :branch => "master"
  conf.gem :github => "diclophis/mruby-wslay", :branch => "fix-intended-return-of-exceptions-1.0" #TODO: get this merged with upstream https://github.com/tatsuhiro-t/wslay
  conf.gem :github => "Asmod4n/mruby-phr", :branch => "master"
  conf.gem :github => "Asmod4n/mruby-simplemsgpack", :branch => "master" #, :branch => "v2.0"
  conf.gem :github => "mattn/mruby-json", :branch => "master"

  ##Desktop specific
  ##conf.gem :github => "h2so5/mruby-pure-regexp"
  #conf.gem :github => "iij/mruby-tempfile"
  #conf.gem :github => "iij/mruby-process"
  #conf.gem :github => "ksss/mruby-signal"
  ##conf.gem :github => "diclophis/mruby-uv", :branch => "wkndr-patch-1b"
  #conf.gem :github => "mattn/mruby-uv"

  ##http faas routing

  ##centralization of thor into shell3
  #conf.gem :github => 'hfm/mruby-fileutils'

  ##conf.gem :git => "git@github.com:Asmod4n/mruby-linenoise", :branch => "master"
  ##conf.gem :git => "git@github.com:mattn/mruby-uv", :branch => "master"
  ##conf.gem :git => "git@github.com:fastly/mruby-optparse", :branch => "master"
  #conf.gem :github => "fastly/mruby-optparse"

  #conf.cc do |cc|
  #  cc.flags = ["-lm", "-O3"]
  #end

  #conf.disable_cxx_exception
  #conf.enable_cxx_exception
  conf.enable_debug

  #enable_debug
  conf.bins = []
  
  conf.cc do |cc|
    cc.flags = ["-O3", "-DMRB_NO_STDIO"]
    #cc.flags = ["-O3", "-DMRB_UTF8_STRING"]

    #cc.flags = ["-O3", "-DMRB_METHOD_CACHE_SIZE=512", "-DMRB_GC_FIXED_ARENA", "-DMRB_INT64", "-DMRB_GC_ARENA_SIZE=10000"]
    #cc.flags = ["-O3", "-DMRB_METHOD_CACHE_SIZE=512", "-DMRB_GC_FIXED_ARENA", "-DMRB_GC_ARENA_SIZE=10000"]
    #cc.flags = ["-O0", "-DMRB_METHOD_CACHE_SIZE=512", "-DMRB_GC_FIXED_ARENA", "-DMRB_GC_ARENA_SIZE=10000"]
  end
end