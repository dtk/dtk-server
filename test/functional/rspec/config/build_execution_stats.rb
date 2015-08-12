require 'rubygems'
require 'yaml'
require 'active_record'

class TestRun < ActiveRecord::Base
  # "testrun" records time of the test execution, duration, pass rate
  # and contains build number as specified in the yml configuration file
  has_many :testcases
  belongs_to :testsuite
end

dbconfig = YAML.load(File.open('./config/rspec2db.yml'))
ActiveRecord::Base.establish_connection(dbconfig['dbconnection'])

build_id = ARGV[0]
suite_name = dbconfig['options']['suite']

if ARGV[2] == nil
  @query = "select * from test_runs tr, test_suites ts where ts.id = tr.test_suites_id and tr.build LIKE '#{build_id}' and ts.suite LIKE '#{suite_name}' order by tr.created_at desc limit 1"
else
  @query = "select * from test_runs tr, test_suites ts where ts.id = tr.test_suites_id and tr.build LIKE '#{build_id}' and ts.suite LIKE '#{suite_name}' order by tr.created_at desc"
end

report = "Execution stats:\n"
report << "----------------\n"

@build = ""
@success_rate = []
@test_steps_count = 0
@test_steps_pass_count = 0
@test_steps_failed_count = 0
@duration = 0

@test_runs = TestRun.find_by_sql(@query)
@test_runs.each do |test_run|
  @success_rate << ((test_run.example_count.to_i - test_run.failure_count.to_i).to_f / test_run.example_count.to_f) * 100
  @test_steps_count = @test_steps_count + test_run.example_count
  @test_steps_pass_count = @test_steps_pass_count + (test_run.example_count.to_i - test_run.failure_count.to_i)
  @test_steps_failed_count = @test_steps_failed_count + test_run.failure_count
  @duration = @duration + test_run.duration
  @build = test_run.build
end

@rate = @success_rate.inject{ |sum, el| sum + el }.to_f / @success_rate.size
@formatted_rate = sprintf('%.2f', @rate.to_f)
@formatted_duration = sprintf('%.2f', @duration.to_f)

File.open(ARGV[1], 'w') { |f| f.write("#{report}Build name: #{@build}\nDuration: #{@formatted_duration}s\nSuccess rate: #{@formatted_rate}%\nTest steps count: #{@test_steps_count}\nTest steps passed: #{@test_steps_pass_count}\nTest steps failed: #{@test_steps_failed_count}\n") }