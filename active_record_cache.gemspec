# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record_cache/version'
Gem::Specification.new do |spec|
  spec.name          = "active_record_cache"
  spec.version       = ActiveRecordCache::VERSION
  spec.authors       = ["Brian Durand"]
  spec.email         = ["mdobrota@tribune.com", "ddpr@tribune.com"]
  spec.summary       = 'This gem adds a caching layer to ActiveRecord models when finding them by a numeric primary key.'
  spec.description   = 'This gem adds a caching layer to ActiveRecord models when finding them by a numeric primary key.'
  spec.homepage      = ""
 
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activerecord', [">= 3.0.5", "< 4.0"]
  # To test different versions:
  #  temporarily swap one of these for the above (and delete the Gemfile.lock)
  #spec.add_runtime_dependency 'activerecord', '~> 3.0.0'
  #spec.add_runtime_dependency 'activerecord', '~> 3.1.0'
  #spec.add_runtime_dependency 'activerecord', '~> 3.2.0'

  spec.add_runtime_dependency 'sort_by_field', "~> 1.0.1"
 
  spec.add_development_dependency 'rspec', ['>= 2.0.0', '< 3.0']
  spec.add_development_dependency 'sqlite3'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
