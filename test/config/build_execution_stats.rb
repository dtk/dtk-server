require 'rubygems'
require 'yaml'
require 'active_record'

class TestRun < ActiveRecord::Base
  # "testrun" records time of the test execution, duration, pass rate 
  # and contains build number as specified in the yml configuration file  
  has_many :testcases
  belongs_to :testsuite
end

dbconfig = YAML::load(File.open('./test/config/rspec2db.yml'))
ActiveRecord::Base.establish_connection(dbconfig["dbconnection"])

build_id = ARGV[0]
@query = "select * from test_runs where build LIKE '#{build_id}'"

@test_runs = TestRun.find_by_sql(@query)
@test_runs.each do |test_run|
  @success_rate = ((test_run.example_count.to_i - test_run.failure_count.to_i).to_f/test_run.example_count.to_f)*100
  @formatted_rate = sprintf("%.2f", @success_rate)
  @formatted_duration = sprintf("%.2f", test_run.duration.to_f)

  File.open(ARGV[1], 'w') {|f| f.write("Build: #{test_run.build}\nDuration: #{@formatted_duration}s\nSuccess rate: #{@formatted_rate}%") }
end