# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chatrix/version'

Gem::Specification.new do |spec|
  spec.name          = 'chatrix'
  spec.version       = Chatrix::VERSION
  spec.authors       = ['Adam Hellberg']
  spec.email         = ['sharparam@sharparam.com']

  spec.summary       = 'Ruby implementation of the Matrix API'
  # spec.description   = %q{}
  spec.homepage      = 'https://github.com/Sharparam/chatrix'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'httparty', '~> 0.13'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'yard', '~> 0.8'
  spec.add_development_dependency 'redcarpet', '~> 3.3'
  spec.add_development_dependency 'rubocop', '~> 0.40.0'
  spec.add_development_dependency 'codeclimate-test-reporter'
end
