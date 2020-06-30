#

MRuby::Build.new do |conf|
  # load specific toolchain settings
  toolchain :gcc

  #enable_debug

  conf.bins = ["mrbc", "mirb"]

  conf.gem :core => "mruby-bin-mrbc"
  conf.gem :core => "mruby-bin-mirb"
  conf.gem :core => "mruby-math"
  conf.gem :core => "mruby-random"
  conf.gem :core => "mruby-enum-ext"
  conf.gem :core => "mruby-struct"
  conf.gem :core => "mruby-metaprog"
  conf.gem :core => "mruby-sprintf"
  conf.gem :core => "mruby-string-ext"
  conf.gem :core => "mruby-eval"
  conf.gem :core => "mruby-pack"

  #conf.gem :core => "mruby-io"

  ##conf.gem :github => "h2so5/mruby-pure-regexp"
  #conf.gem :github => "yui-knk/mruby-set"
  #conf.gem :github => "Asmod4n/mruby-simplemsgpack"

  ##Desktop specific
  #conf.gem :github => "iij/mruby-tempfile"
  #conf.gem :github => "iij/mruby-process"
  #conf.gem :github => "ksss/mruby-signal"
  ##conf.gem :github => "diclophis/mruby-uv", :branch => "wkndr-patch-1b"
  #conf.gem :github => "mattn/mruby-uv"

  #conf.gem :github => "diclophis/mruby-wslay", :branch => "fix-intended-return-of-exceptions-1.0"
  #conf.gem :github => "Asmod4n/mruby-b64"
  #conf.gem :github => "Asmod4n/mruby-phr"

  ##http faas routing
  #conf.gem :github => "katzer/mruby-r3"

  #conf.gem :github => "iij/mruby-zlib"

  ##centralization of thor into shell3
  #conf.gem :github => 'hfm/mruby-fileutils'

  ##conf.gem :git => "git@github.com:Asmod4n/mruby-linenoise", :branch => "master"
  ##conf.gem :git => "git@github.com:mattn/mruby-uv", :branch => "master"
  ##conf.gem :git => "git@github.com:fastly/mruby-optparse", :branch => "master"
  #conf.gem :github => "fastly/mruby-optparse"

  #conf.cc do |cc|
  #  cc.flags = ["-lm", "-O3"]
  #end

  #conf.enable_cxx_exception
  #conf.disable_cxx_exception
end
