# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sinatra/paypal/version'

Gem::Specification.new do |spec|
  spec.name          = "sinatra-paypal"
  spec.version       = Sinatra::Paypal::VERSION
  spec.authors       = ["Nathan Reed"]
  spec.email         = ["reednj@gmail.com"]

  spec.summary       = %q{Easy validation and processing of Paypal IPN payments}
  spec.homepage      = "http://github.com/reednj/sinatra-paypal"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "rack-test"
  spec.add_runtime_dependency "sinatra"
  spec.add_runtime_dependency "rest-client"
end
