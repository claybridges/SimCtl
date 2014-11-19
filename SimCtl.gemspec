# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'SimCtl/version'

Gem::Specification.new do |spec|
  spec.name          = "SimCtl"
  spec.version       = SimCtl::VERSION
  spec.authors       = ["Clay Bridges"]
  spec.email         = ["claybridges@gmail.com"]
  spec.summary       = %q{A Ruby wrapper for Xcode simctl}
#  spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = "http://github.com/claybridges/SimCtl"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
