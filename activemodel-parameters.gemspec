# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_model/parameters/version'

Gem::Specification.new do |spec|
  spec.name          = "activemodel-parameters"
  spec.version       = ActiveModel::PARAMETERS_VERSION
  spec.authors       = ["Chris Keele"]
  spec.email         = ["dev@chriskeele.com"]
  spec.description   = %q{Making it easy to transform parameter hashes into model attributes}
  spec.summary       = %q{Bringing consistency and object orientation to parameter transformation. Compliments active_model_serializers.}
  spec.homepage      = "https://github.com/christhekeele/activemodel-parameters"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", ">= 3.2"
  spec.add_dependency "activesupport", ">= 3.2"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rails", ">= 3.2"
end
