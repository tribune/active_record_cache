# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record_cache/version'
Gem::Specification.new do |spec|
  spec.name          = "active_record_cache"
  spec.version       = ActiveRecordCache::VERSION.dup  # dup for ruby 1.9
  spec.authors       = ["Brian Durand"]
  spec.email         = ["mdobrota@tribune.com", "ddpr@tribune.com"]
  spec.summary       = 'This gem adds a caching layer to ActiveRecord models when finding them by a numeric primary key.'
  spec.description   = 'This gem adds a caching layer to ActiveRecord models when finding them by a numeric primary key.'
  spec.homepage      = ""
 
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'activerecord', ">= 3.2", "< 4.3"
  spec.add_dependency 'sort_by_field', "~> 1.0.1"
 
  spec.add_development_dependency 'rspec', '~> 2.99'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency "bundler"  , "~> 1.7"
  spec.add_development_dependency "rake"     , "~> 10.0"
  spec.add_development_dependency "appraisal", "~> 2.0"
end
