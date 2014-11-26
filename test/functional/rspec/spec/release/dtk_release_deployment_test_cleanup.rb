#!/usr/bin/env ruby
# This job is used to delete DTK release deployment test service instance if deployed successfully

require './lib/dtk_common'

service_id = ARGV[0]
dtk_common = DtkCommon.new('', '')
dtk_common.delete_and_destroy_service(service_id)