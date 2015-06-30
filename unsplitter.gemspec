# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'unsplitter/version'

Gem::Specification.new do |spec|
  spec.name          = "unsplitter"
  spec.version       = Unsplitter::VERSION
  spec.authors       = ["Telmate"]
  spec.email         = ["support@telmate.com"]
  spec.summary       = %q{For split brain databases}
  spec.description   = %q{Stream consistent records between databases}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 4.1.5"
  spec.add_dependency "activerecord-jdbcmysql-adapter"
  spec.add_dependency "hashdiff"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
