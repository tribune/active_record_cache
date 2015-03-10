# coding: utf-8
require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
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
    raise "You must have rspec installed to run the tests"
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
    # dependencies defined in Gemfile
  end
  Jeweler::RubygemsDotOrgTasks.new
rescue LoadError
end
