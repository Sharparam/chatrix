# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ratrix/version'

Gem::Specification.new do |spec|
    spec.name          = "ratrix"
    spec.version       = Ratrix::VERSION
    spec.authors       = ["Adam Hellberg"]
    spec.email         = ["sharparam@sharparam.com"]

    spec.summary       = %q{Ruby implementation of the Matrix API}
    #spec.description   = %q{}
    spec.homepage      = "https://github.com/Sharparam/ratrix"
    spec.license       = "MIT"

    spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
    spec.bindir        = "exe"
    spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
    spec.require_paths = ["lib"]

    spec.add_runtime_dependency "httparty", "~> 0.13"

    spec.add_development_dependency "bundler", "~> 1.12"
    spec.add_development_dependency "rake", "~> 10.0"
    spec.add_development_dependency "rspec", "~> 3.0"
    spec.add_development_dependency "pry", "~> 0.10"
end
