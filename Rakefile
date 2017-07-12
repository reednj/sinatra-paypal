require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
    ENV['RUBYOPT'] = '-W0'
    t.warning = false
    t.test_files = FileList['test/*_test.rb']
end
