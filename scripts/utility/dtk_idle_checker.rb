#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'fog'

def instance_status(aws_connection, instance_id)
  response = aws_connection.describe_instances('instance-id' => instance_id)
  unless response.nil?
    status = response.body['reservationSet'].first['instancesSet'].first['instanceState']['name'].to_sym
    launch_time = response.body['reservationSet'].first['instancesSet'].first['launchTime']
    { status: status, launch_time: launch_time, up_time_hours: ((Time.now - launch_time) / 3600).round }
  end
end

# unless ENV['DTK_AWS_KEY_ID'] || ENV['DTK_AWS_KEY_SECRET']
#   abort("Missing requeired 'DTK_AWS_KEY_ID' and 'DTK_AWS_KEY_SECRET' to successfully run this script, aborting ... ")
# end

# will use .fog file if env not set
aws_conn = Fog::Compute::AWS.new()

aws_conn.servers.all('instance-state-name' => 'running', 'tag-key' => 'service.instance.ttl').each do |server_instance|
  status = instance_status(aws_conn, server_instance.id)
  service_instance_ttl = server_instance.tags.fetch('service.instance.ttl').to_i
  next if service_instance_ttl.zero?
  if status[:up_time_hours] >= service_instance_ttl
    puts "Stopping server instance: #{server_instance.id}"

    aws_conn.stop_instances(server_instance.id)
  end
end

puts "Stop long running instances script ... Done"