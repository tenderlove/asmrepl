require "rake/testtask"
require "rake/clean"

ENV["MT_NO_PLUGINS"] = "1"

file "lib/asmrepl/parser.tab.rb" => "lib/asmrepl/parser.y" do |t|
  sh "racc -l -o #{t.name} #{t.prerequisites.first}"
end

task :compile => "lib/asmrepl/parser.tab.rb"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
  t.warning = true
end

task :autotest do
  sh "fswatch -o lib test | xargs -n1 -I{} bundle exec rake test"
end

task :test => :compile
