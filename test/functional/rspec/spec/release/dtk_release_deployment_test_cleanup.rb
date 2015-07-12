#!/usr/bin/env ruby
# This job is used to delete DTK release deployment test service instance if deployed successfully
require './lib/dtk_common'

dtk_common = Common.new('', '')
services = dtk_common.list_specific_success_service("dtk_release_deployment_test")
services.each do |s|
  dtk_common.delete_and_destroy_service(s['id'])
end

failed_services = dtk_common.list_specific_failed_service('dtk_release_deployment_test')
failed_services.each do |s|
  dtk_common.stop_running_service(s['id'])
end
