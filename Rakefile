# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

require 'rake/testtask'

namespace :test do
  desc "Test texters"
  Rake::TestTask.new(texters: 'test:prepare') do |t|
    t.libs << "test"
    t.pattern = 'test/texters/**/*_test.rb'
  end
end


Rails.application.load_tasks
