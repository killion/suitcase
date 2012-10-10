require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
  t.libs.push 'test'
end

task :default => :test

task :install_nodoc => [:build] do
  system "gem install pkg/suitcase-#{Suitcase::VERSION}.gem --no-ri --no-rdoc"
end
