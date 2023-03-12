#

MRuby::Build.new do |conf|
  # load specific toolchain settings
  toolchain :gcc

  enable_debug

  conf.bins = ["mrbc"]

  conf.gem :core => "mruby-bin-mrbc"
  conf.gem :core => "mruby-bin-mirb"

  conf.cc do |cc|
    cc.flags = ["-O3"]
  end
end
