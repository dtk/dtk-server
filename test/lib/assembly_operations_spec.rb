require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

STDOUT.sync = true

shared_context "Stage" do |dtk_common|
  it "stages assembly from assembly template" do
    $assembly_id = dtk_common.stage_assembly()    
    $assembly_id.should_not eq(nil)
    puts "Stage completed successfully!"
  end
end

shared_context "List assemblies after stage" do |dtk_common|
  unless $assembly_id.nil?
    it "has staged assembly in assembly list" do
      assembly_exists = dtk_common.check_if_assembly_exists($assembly_id)
      assembly_exists.should eq(true)
      puts "Assembly exists in assembly list."
    end
  end
end

shared_context "Converge" do |dtk_common|
  unless $assembly_id.nil?
    it "converges assembly" do
      converge = dtk_common.converge_assembly($assembly_id)
      converge.should eq("succeeded")
      puts "Assembly converged successfully!"
    end
  end
end

shared_context "Check if port avaliable" do |dtk_common, port|
  unless $assembly_id.nil?
    it "exists" do
      netstat_response = dtk_common.netstats_check($assembly_id)
      namenode_port = netstat_response['data']['results'].select { |x| x['port'] == port}.first['port']
      namenode_port.should eq(port)
      puts "Service up and running on deployed instance (port #{port} avaliable)."
    end
  end
end

shared_context "Stop assembly" do |dtk_common|
  unless $assembly_id.nil?
    it "stops assembly" do
      stop_status = dtk_common.stop_running_assembly($assembly_id)
      stop_status.should eq("ok")
      puts "Assembly stopped successfully!"
    end
  end
end

shared_context "Delete assemblies" do |dtk_common|
  unless $assembly_id.nil?
    it "deletes assembly" do
      assembly_deleted = dtk_common.delete_and_destroy_assembly($assembly_id)
      assembly_deleted.should eq("ok")
      puts "Assembly deleted successfully!"
    end
  end
end

shared_context "List assemblies after delete" do |dtk_common|
  unless $assembly_id.nil?
    it "doesn't have assembly in assembly list" do
      assembly_exists = dtk_common.check_if_assembly_exists($assembly_id)
      assembly_exists.should eq(false)
      puts "Assembly does not exist in assembly list since it was deleted previously."
    end
  end
end

shared_context "Delete assembly template" do |dtk_common, assembly_template_name|
  it "deletes assembly template" do
    assembly_template_deleted = dtk_common.delete_assembly_template(assembly_template_name)
    assembly_template_deleted.should eq("ok")
    puts "Assembly template deleted successfully!"
  end
end

shared_context "Create assembly template from assembly" do |dtk_common, service_name, assembly_template_name|
  it "creates assembly template in given service from existing assembly" do
    assembly_template_created = dtk_common.create_assembly_template_from_assembly($assembly_id, service_name, assembly_template_name)
    assembly_template_created.should eq(true)
  end
end