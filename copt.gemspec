# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'copt/version'

Gem::Specification.new do |spec|
  spec.name          = "copt"
  spec.version       = Copt::VERSION
  spec.authors       = ["Ernesto Garcia"]
  spec.email         = ["gnapse@gmail.com"]
  spec.description   = %q{A command line options parser designed for scripts that need to support subcommands.}
  spec.summary       = %q{A command line options parser with great subcommands support.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
