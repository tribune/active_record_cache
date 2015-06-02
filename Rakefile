# coding: utf-8
require 'bundler/gem_tasks'
require 'bundler/setup'  # constrain rake version

# Note: if you get this error: "Bundler could not find compatible versions for gem ..."
# try deleting Gemfile.lock (usually happens when switching branches).

task default: :appraise_all

# This is slightly different from 'appraisal COMMAND' because it continues even if a definition fails.
desc "Run rspecs for all appraisals"
task :appraise_all do
  success_map = {}
  `bundle exec appraisal list`.lines.map(&:chomp).each do |appraise_def|
     success = system('appraisal', appraise_def, 'rspec', 'spec')
     success_map[appraise_def] = success
  end
  puts "\n===== Test Summary ====="
  success_map.each do |appraise_def, success|
    puts "#{appraise_def}: #{success ? 'no failures (but check pending)' : 'failed'}"
  end
end
