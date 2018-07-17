# coding: utf-8

#lib = File.expand_path('../lib', __FILE__)
#$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

#require 'termios/version'

Gem::Specification.new do |spec|
  spec.name          = 'wkndr'
  spec.version       = "0.0.0" 
  spec.authors       = ['foo']
  spec.email         = ['foo']

  spec.summary       = ''
  spec.description   = <<-E
foo
                       E
  spec.homepage      = 'https://github.com/diclophis/wkndr'
  spec.license       = "GPL"

  spec.files         = ["Thorfile"]
  #`git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  #spec.bindir        = 'bin'
  #spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  #spec.require_paths = ['lib']
  spec.extensions    = ['ext/extconf.rb']

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rake-compiler'
end
