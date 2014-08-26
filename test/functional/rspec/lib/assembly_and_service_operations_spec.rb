require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context "Stage" do |dtk_common|
  it "stages #{dtk_common.service_name} service from assembly" do
    dtk_common.stage_service()    
    dtk_common.service_id.should_not eq(nil)
  end
end

shared_context "Rename service" do |dtk_common, new_service_name|
  it "renames #{dtk_common.service_name} service to #{new_service_name}" do
    service_renamed = dtk_common.rename_service(dtk_common.service_id, new_service_name)
    service_renamed.should eq(true)
  end
end

shared_context "NEG - Rename service to existing name" do |dtk_common, service_name, new_service_name|
  it "does not rename #{service_name} service to #{new_service_name} since #{new_service_name} already exists" do
    puts "NEG - Rename service to existing name:", "---------------------------------------"
    pass = false
    value = `dtk service rename #{service_name} #{new_service_name}`
    puts value
    pass = true if value.include? "[ERROR] Service with name '#{new_service_name}' exists already."
    puts "Rename did not passed successfully which is expected!" if pass == true
    puts "Rename passed successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "NEG - Rename service to workspace name" do |dtk_common, service_name|
  it "does not rename #{service_name} service to workspace since workspace is special type of service" do
    puts "NEG - Rename service to workspace name:", "----------------------------------------"
    pass = false
    value = `dtk service rename #{service_name} workspace`
    puts value
    pass = true if value.include? "[ERROR] You are not allowed to use keyword 'workspace' as service name."
    puts "Rename did not passed successfully which is expected!" if pass == true
    puts "Rename passed successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "List services after stage" do |dtk_common|
  it "has staged #{dtk_common.service_name} service in service list" do
    service_exists = dtk_common.check_if_service_exists(dtk_common.service_id)
    service_exists.should eq(true)
  end
end

shared_context "NEG - List services" do |dtk_common|
  it "does not have #{dtk_common.service_name} service in service list" do
    service_exists = dtk_common.check_if_service_exists(dtk_common.service_id)
    service_exists.should eq(false)
  end
end

shared_context "Converge" do |dtk_common|
  it "converges #{dtk_common.service_name} service" do
    converge = dtk_common.converge_service(dtk_common.service_id)
    converge.should eq(true)
  end
end

# converge with parametrized max retries
shared_context "Converge service" do |dtk_common, max_retries|
  it "converges #{dtk_common.service_name} service" do
    converge = dtk_common.converge_service(dtk_common.service_id, max_retries)
    converge.should eq(true)
  end
end

shared_context "Check if port avaliable" do |dtk_common, port|
  it "is avaliable" do
    netstat_response = dtk_common.netstats_check(dtk_common.service_id, port)
    netstat_response.should eq(true)
  end
end

shared_context "Check if port avaliable on specific node" do |dtk_common, node_name, port|
  it "is avaliable on #{node_name} node" do
    netstat_response = dtk_common.netstats_check_for_specific_node(dtk_common.service_id, node_name, port)
    netstat_response.should eq(true)
  end
end

shared_context "Stop service" do |dtk_common|
  it "stops #{dtk_common.service_name} service " do
    stop_status = dtk_common.stop_running_service(dtk_common.service_id)
    stop_status.should eq(true)
  end
end

shared_context "Delete services" do |dtk_common|
  it "deletes #{dtk_common.service_name} service" do
    service_deleted = dtk_common.delete_and_destroy_service(dtk_common.service_id)
    service_deleted.should eq(true)
  end
end

shared_context "List services after delete" do |dtk_common|
  it "doesn't have #{dtk_common.service_name} service in service list" do
    service_exists = dtk_common.check_if_service_exists(dtk_common.service_id)
    service_exists.should eq(false)
  end
end

shared_context "Delete assembly" do |dtk_common, assembly_name, namespace|
  it "deletes #{assembly_name} assembly" do
    assembly_deleted = dtk_common.delete_assembly(assembly_name, namespace)
    assembly_deleted.should eq(true)
  end
end

shared_context "Create assembly from service" do |dtk_common, service_name, assembly_name|
  it "creates #{assembly_name} assembly in #{service_name} service module from existing service" do
    assembly_created = dtk_common.create_assembly_from_service(dtk_common.service_id, service_name, assembly_name)
    assembly_created.should eq(true)
  end
end

shared_context "Grep log command" do |dtk_common, node_name, log_location, grep_pattern|
  it "finds #{grep_pattern} pattern in #{log_location} log on converged node" do
    grep_pattern_found = dtk_common.grep_node(dtk_common.service_id, node_name, log_location, grep_pattern)
    grep_pattern_found.should eq(true)
  end
end

shared_context "List component dependencies" do |dtk_common, source_component, dependency_component, dependency_satisfied_by|
  it "checks that #{source_component} has dependency on #{dependency_component} and that dependency is satisfied by #{dependency_satisfied_by}" do
    dependency_found = dtk_common.check_component_depedency(dtk_common.service_id, source_component, dependency_component, dependency_satisfied_by)
    dependency_found.should eq(true)
  end
end