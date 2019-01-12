require 'bundler/gem_tasks'

#require 'rake/extensiontask'
#Rake::ExtensionTask.new('termios') do |ext|
#  ext.ext_dir = 'ext'
#  ext.lib_dir = 'lib'
#end
#task :default => [:clobber, :compile]

task :submodules do
  system("git submodule add https://github.com/mruby/mruby")
  system("git submodule init")
  system("git submodule update")
  #system("git submodule add https://github.com/raysan5/raylib")
end

task :default => [:submodules]
