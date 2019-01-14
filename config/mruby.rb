#

MRuby::Build.new do |conf|
  # load specific toolchain settings
  toolchain :gcc

  enable_debug

  conf.bins = ["mrbc", "mirb"]

  conf.gem :core => "mruby-bin-mirb"
  conf.gem :core => "mruby-math"
  conf.gem :core => "mruby-random"
  conf.gem :core => "mruby-io"
  conf.gem :core => "mruby-enum-ext"
  conf.gem :core => "mruby-struct"
  conf.gem :core => "mruby-metaprog"
  conf.gem :core => "mruby-sprintf"
  conf.gem :core => "mruby-string-ext"

  conf.gem :github => "h2so5/mruby-pure-regexp"
  conf.gem :github => "yui-knk/mruby-set"
  conf.gem :github => "Asmod4n/mruby-simplemsgpack"

  #Desktop specific
  conf.gem :github => "iij/mruby-tempfile"
  conf.gem :github => "iij/mruby-process"
  conf.gem :github => "ksss/mruby-signal"
  conf.gem :github => "diclophis/mruby-uv", :branch => "wkndr-patch-1"
  conf.gem :github => "diclophis/mruby-wslay", :branch => "fix-intended-return-of-exceptions-1.0"
  conf.gem :github => "Asmod4n/mruby-b64"
  conf.gem :github => "Asmod4n/mruby-phr"

  conf.cc do |cc|
    cc.flags = ["-lm"] #ENV['CFLAGS'], "-lm"].join(" ")
  end
end
