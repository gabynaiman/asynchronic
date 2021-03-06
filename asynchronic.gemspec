# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'asynchronic/version'

Gem::Specification.new do |spec|
  spec.name          = 'asynchronic'
  spec.version       = Asynchronic::VERSION
  spec.authors       = ['Gabriel Naiman']
  spec.email         = ['gabynaiman@gmail.com']
  spec.description   = 'DSL for asynchronic pipeline'
  spec.summary       = 'DSL for asynchronic pipeline using queues over Redis'
  spec.homepage      = 'https://github.com/gabynaiman/asynchronic'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'ost', '~> 1.0'
  spec.add_dependency 'broadcaster', '~> 1.0', '>= 1.0.2'
  spec.add_dependency 'class_config', '~> 0.0'
  spec.add_dependency 'transparent_proxy', '~> 0.0'
  spec.add_dependency 'multi_require', '~> 1.0'

  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'minitest', '~> 5.0', '< 5.11'
  spec.add_development_dependency 'minitest-great_expectations', '~> 0.0'
  spec.add_development_dependency 'minitest-stub_any_instance', '~> 1.0'
  spec.add_development_dependency 'minitest-colorin', '~> 0.1'
  spec.add_development_dependency 'minitest-line', '~> 0.6'
  spec.add_development_dependency 'simplecov', '~> 0.12'
  spec.add_development_dependency 'coveralls', '~> 0.8'
  spec.add_development_dependency 'pry-nav', '~> 0.2'
end
