require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb", "test/**/test_*.rb"]
end

desc "Run tests with actual model execution"
task :test_with_models do
  # Run tests with actual model execution
  ENV["LLMALFR_RUN_MODEL_TESTS"] = "true"
  Rake::Task["test"].invoke
end

task :default => :test
