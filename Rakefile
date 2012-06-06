require 'rubygems'
require 'rake'

desc 'Default: run unit tests'
task :default => :test

begin
  require 'rspec'
  require 'rspec/core/rake_task'
  desc 'Run the unit tests'
  RSpec::Core::RakeTask.new(:test)
rescue LoadError
  task :test do
    raise "You must have rspec 2.0 installed to run the tests"
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "active_record_cache"
    gem.summary = %Q{This gem adds a caching layer to ActiveRecord models when finding them by a numeric primary key.}
    gem.description = %Q{This gem adds a caching layer to ActiveRecord models when finding them by a numeric primary key.}
    gem.authors = ["Brian Durand"]
    gem.email = ["mdobrota@tribune.com", "ddpr@tribune.com"]
    gem.files = FileList["lib/**/*", "spec/**/*", "bin/**/*", "example/**/*" "README.rdoc", "Rakefile", "License.txt"].to_a
    gem.has_rdoc = true
    gem.rdoc_options << '--line-numbers' << '--inline-source' << '--main' << 'README.rdoc'
    gem.extra_rdoc_files = ["README.rdoc"]
    gem.add_dependency('activerecord', "~>3.0.5")
    gem.add_dependency('tribune-sort_by_field', "~>1.0.1")
    gem.add_development_dependency('rspec', '>= 2.0.0')
    gem.add_development_dependency('sqlite3')
  end
  Jeweler::RubygemsDotOrgTasks.new
rescue LoadError
end
