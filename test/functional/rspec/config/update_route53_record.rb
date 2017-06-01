require 'fog'

hosted_zone_id = ARGV[0]
record = ARGV[1]
new_value = ARGV[2]
use_iam_instance_profile = ARGV[3]

dns = nil

if use_iam_instance_profile
  dns = Fog::DNS.new({:provider => 'AWS', :use_iam_profile => true })
else
  dns = Fog::DNS.new({:provider => 'AWS'})
end

zone = dns.zones.get(hosted_zone_id)
record_name = zone.records.get(record)

change_batch_options = [
  {
    :action => "DELETE",
    :name => record,
    :type => "CNAME",
    :ttl => 5,
    :resource_records => [ record_name.value.first ]
  },
  {
    :action => "CREATE",
    :name => record,
    :type => "CNAME",
    :ttl => 5,
    :resource_records => [ new_value ]
  }
]

dns.change_resource_record_sets(hosted_zone_id, change_batch_options)
