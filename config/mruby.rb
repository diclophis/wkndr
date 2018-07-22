
MRuby::Build.new do |conf|
  # load specific toolchain settings
  toolchain :gcc

  enable_debug

  conf.bins = ["mrbc", "mirb"]

  conf.gem :core => "mruby-bin-mirb"
  conf.gem :core => "mruby-struct"
  conf.gem :core => "mruby-io"
  conf.gem :core => "mruby-sprintf"
  conf.gem :core => "mruby-string-ext"

  conf.gem :github => "h2so5/mruby-pure-regexp"
  conf.gem :github => "yui-knk/mruby-set"
  conf.gem :github => "iij/mruby-tempfile"
  conf.gem :github => "iij/mruby-process"

  conf.cc do |cc|
    cc.flags = [ENV['CFLAGS'], "-lm"].join(" ")
  end
end
