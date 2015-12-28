require 'fog'
require 'ap'

tenant_logs_location = ARGV[0]
bucket_name = "tenant-regression-logs"

connection = Fog::Storage.new({:provider => 'AWS'})
directory = connection.directories.get(bucket_name)

time = Time.new
time_string = time.year.to_s + time.month.to_s + time.day.to_s + "-" + time.hour.to_s + time.min.to_s + time.sec.to_s

file = directory.files.create(
  :key    => "dtk-server-log-#{time_string}",
  :body   => File.open(tenant_logs_location),
  :public => false
)

puts "List of current logs on the #{bucket_name} S3 bucket:"
directory.files.each do |file|
	ap file.key
end