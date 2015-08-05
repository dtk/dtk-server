require 'fog'

def instance_status(aws_connection, instance_id)
  response = aws_connection.describe_instances('instance-id' => instance_id)
  unless response.nil?
    status = response.body['reservationSet'].first['instancesSet'].first['instanceState']['name'].to_sym
    launch_time = response.body['reservationSet'].first['instancesSet'].first['launchTime']
    { status: status, launch_time: launch_time, up_time_hours: ((Time.now - launch_time) / 3600).round }
  end
end

unless ENV['DTK_AWS_KEY_ID'] || ENV['DTK_AWS_KEY_SECRET']
  abort("Missing requeired 'DTK_AWS_KEY_ID' and 'DTK_AWS_KEY_SECRET' to successfully run this script, aborting ... ")
end

aws_conn = Fog::Compute::AWS.new(:aws_access_key_id => ENV['DTK_AWS_KEY_ID'], :aws_secret_access_key => ENV['DTK_AWS_KEY_SECRET'])

aws_conn.servers.all('instance-state-name' => 'running', 'tag-key' => 'service.instance.ttl').each do |server_instance|
  status = instance_status(aws_conn, server_instance.id)
  if status[:up_time_hours] >= server_instance.tags.fetch('service.instance.ttl').to_i
    puts "Stopping server instance: #{server_instance.id}"

    aws_conn.stop_instances(server_instance.id)
  end
end

puts "Stop long running instances script ... Done"