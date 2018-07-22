require 'bundler/gem_tasks'
require 'rake/extensiontask'

Rake::ExtensionTask.new('termios') do |ext|
  ext.ext_dir = 'ext'
  ext.lib_dir = 'lib'
end

task :submodule_mruby do
  system("git submodule add https://github.com/mruby/mruby")
end

task :default => [:clobber, :compile]
