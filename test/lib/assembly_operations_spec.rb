require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

STDOUT.sync = true

shared_context "Stage" do |dtk_common|
  it "stages #{dtk_common.assembly_name} assembly from assembly template" do
    $assembly_id = dtk_common.stage_assembly()    
    $assembly_id.should_not eq(nil)
  end
end

shared_context "List assemblies after stage" do |dtk_common|
  it "has staged #{dtk_common.assembly_name} assembly in assembly list" do
    assembly_exists = dtk_common.check_if_assembly_exists($assembly_id)
    assembly_exists.should eq(true)
  end
end

shared_context "NEG - List assemblies" do |dtk_common|
  it "does not have #{dtk_common.assembly_name} assembly in assembly list" do
    assembly_exists = dtk_common.check_if_assembly_exists($assembly_id)
    assembly_exists.should eq(false)
  end
end

shared_context "Converge" do |dtk_common|
  it "converges #{dtk_common.assembly_name} assembly" do
    converge = dtk_common.converge_assembly($assembly_id)
    converge.should eq(true)
  end
end

shared_context "Check if port avaliable" do |dtk_common, port|
  it "is avaliable" do
    netstat_response = dtk_common.netstats_check($assembly_id, port)
    netstat_response.should eq(true)
  end
end

shared_context "Stop assembly" do |dtk_common|
  it "stops #{dtk_common.assembly_name} assembly" do
    stop_status = dtk_common.stop_running_assembly($assembly_id)
    stop_status.should eq(true)
  end
end

shared_context "Delete assemblies" do |dtk_common|
  it "deletes #{dtk_common.assembly_name} assembly" do
    assembly_deleted = dtk_common.delete_and_destroy_assembly($assembly_id)
    assembly_deleted.should eq(true)
  end
end

shared_context "List assemblies after delete" do |dtk_common|
  it "doesn't have #{dtk_common.assembly_name} assembly in assembly list" do
    assembly_exists = dtk_common.check_if_assembly_exists($assembly_id)
    assembly_exists.should eq(false)
  end
end

shared_context "Delete assembly template" do |dtk_common, assembly_template_name|
  it "deletes #{assembly_template_name} assembly template" do
    assembly_template_deleted = dtk_common.delete_assembly_template(assembly_template_name)
    assembly_template_deleted.should eq(true)
  end
end

shared_context "Create assembly template from assembly" do |dtk_common, service_name, assembly_template_name|
  it "creates #{assembly_template_name} assembly template in #{service_name} service from existing assembly" do
    assembly_template_created = dtk_common.create_assembly_template_from_assembly($assembly_id, service_name, assembly_template_name)
    assembly_template_created.should eq(true)
  end
end

shared_context "Grep log command" do |dtk_common, node_name, log_location, grep_pattern|
  it "finds #{grep_pattern} pattern in #{log_location} log on converged node" do
    grep_pattern_found = dtk_common.grep_node($assembly_id, node_name, log_location, grep_pattern)
    grep_pattern_found.should eq(true)
  end
end