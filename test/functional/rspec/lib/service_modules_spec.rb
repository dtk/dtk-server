require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

STDOUT.sync = true

#shared_context "Import service module" do |dtk_common, service_module_name|
#  it "imports new service module #{service_module_name}" do
#    service_module_created = dtk_common.import_new_service_module(service_module_name)
#    service_module_created.should eq(true)
#  end
#end

shared_context "Import service module" do |service_module_name|
  it "imports #{service_module_name} service module from local filesystem to server" do
    puts "Import service module:", "----------------------"
    pass = true
    value = `dtk service-module import #{service_module_name}`
    puts value
    pass = false if ((value.include? "ERROR") || (value.include? "exists already"))
    puts "Import of service module #{service_module_name} completed successfully!" if pass == true
    puts "Import of service module #{service_module_name} did not complete successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Import remote service module" do |dtk_common, service_module_name|
  it "imports #{service_module_name} service module from remote repo" do
    puts "Import remote service module:", "-----------------------------"
    pass = true
    value = `dtk service-module install #{service_module_name} -y`
    puts value
    pass = false if ((value.include? "ERROR") || (value.include? "exists on client"))
    puts "Import of remote service module #{service_module_name} completed successfully!" if pass == true
    puts "Import of remote service module #{service_module_name} did not complete successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "NEG - Import remote service module" do |dtk_common, service_module_name|
  it "will not import #{service_module_name} service module from remote repo since there are referenced component modules on local filesystem which are not deleted" do
    puts "NEG - Import remote service module:", "-----------------------------------"
    pass = false
    value = `dtk service-module install #{service_module_name}`
    puts value
    pass = true if (value.include? "exists on client")
    puts "Import of remote service module #{service_module_name} did not complete successfully because of the referenced component module that exists on local filesystem!" if pass == true
    puts "Import of remote service module #{service_module_name} completed successfully which is not expected!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Check service module imported on local filesystem" do |service_module_filesystem_location, service_module_name|
  it "checks that #{service_module_name} service module is imported on local filesystem on location #{service_module_filesystem_location}" do
    puts "Check service module imported on local filesystem:", "--------------------------------------------------"
    pass = false
    `ls #{service_module_filesystem_location}/#{service_module_name}`
    pass = true if $?.exitstatus == 0
    if (pass == true)
      puts "Service module #{service_module_name} imported on local filesystem successfully!" 
    else
      puts "Service module #{service_module_name} was not imported on local filesystem successfully!"
    end
    puts ""
    pass.should eq(true)
  end
end

shared_context "Check component modules in service module" do |dtk_common, service_module_name, components_list_to_check|
  it "verifies that all component modules #{components_list_to_check.inspect} exist in #{service_module_name} service module" do
    components_exist = dtk_common.check_component_modules_in_service_module(service_module_name, components_list_to_check)
    components_exist.should eq(true)
  end
end

shared_context "List all service modules" do |dtk_common, service_module_name|
  it "verifies that #{service_module_name} service module exists on server" do
    service_module_exists = dtk_common.check_if_service_module_exists(service_module_name)
    service_module_exists.should eq(true)
  end
end

shared_context "NEG - List all service modules" do |dtk_common, service_module_name|
  it "verifies that #{service_module_name} service module does not exist on server" do
    service_module_exists = dtk_common.check_if_service_module_exists(service_module_name)
    service_module_exists.should eq(false)
  end
end

shared_context "List all service modules on remote" do |dtk_common, service_module_name, namespace|
  it "verifies that #{service_module_name} service module exists on remote" do
    puts "List all service modules on remote:", "-----------------------------------"
    pass = false
    value = `dtk service-module list --remote`
    pass = true if value.include? "#{namespace}/#{service_module_name}"
    puts "List of service modules on remote contains service module #{service_module_name} on namespace #{namespace}" if pass == true
    puts "List of service modules on remote does not contain service module #{service_module_name} on namespace #{namespace}" if pass == false
    puts ""
    pass.should eq(true)
  end
end

#shared_context "OLD - List all services on remote" do |dtk_common, service_module_name, namespace|
#  it "verifies that #{service_module_name} service exists on remote" do
#    service_exists = dtk_common.check_if_service_exists_on_remote(service_module_name, namespace)
#    service_exists.should eq(true)
#  end
#end

#shared_context "OLD - Export service" do |dtk_common, service_module_name, namespace|
#  it "exports #{service_module_name} service to #{namespace} namespace on remote repo" do
#    service_exported = dtk_common.export_service_to_remote(service_module_name, namespace)
#    service_exported.should eq(true)
#  end
#end

shared_context "Export service module" do |dtk_common, service_module_name, namespace|
  it "exports #{service_module_name} service module to #{namespace} namespace on remote repo" do
    puts "Export service module to remote:", "--------------------------------"
    pass = false
    value = `dtk service-module #{service_module_name} publish #{namespace}/#{service_module_name}`
    puts value
    pass = true if (!value.include? "error")
    puts "Publish of #{service_module_name} service module to #{namespace} namespace has been completed successfully!" if pass == true
    puts "Publish of #{service_module_name} service module to #{namespace} namespace did not complete successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Check if assembly belongs to the service module" do |dtk_common, service_module_name, assembly_name|
  it "verifes that #{assembly_name} assembly is part of the #{service_module_name} service module" do
    assembly_exists_in_service_module = dtk_common.check_if_service_module_contains_assembly(service_module_name, assembly_name)
    assembly_exists_in_service_module.should eq(true)
  end
end

shared_context "Delete service module" do |dtk_common, service_module_name|
  it "deletes #{service_module_name} service module" do
    service_module_deleted = dtk_common.delete_service_module(service_module_name)
    service_module_deleted.should eq(true)
  end
end


shared_context "Delete service module from local filesystem" do |service_module_filesystem_location, service_module_name|
  it "deletes #{service_module_name} service module from local filesystem" do
    puts "Delete service module from local filesystem:", "--------------------------------------------"
    pass = false
    value = `rm -rf #{service_module_filesystem_location}/#{service_module_name}`
    pass = !value.include?("cannot remove")
    puts "Service module #{service_module_name} deleted from local filesystem successfully!" if pass == true
    puts "Service module #{service_module_name} was not deleted from local filesystem successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Delete service module from remote repo" do |dtk_common, service_module_name, namespace|
  it "deletes #{service_module_name} service module with #{namespace} namespace from remote repo" do
    puts "Delete service module from remote (dtkn):", "-----------------------------------------"
    pass = false
    value = `dtk service-module delete-from-catalog #{namespace}/#{service_module_name} -y`
    pass = true if (!value.include?("error") || !value.include?("cannot remove"))
    puts "Service module #{service_module_name} deleted from remote (dtkn) successfully!" if pass == true
    puts "Service module #{service_module_name} was not deleted from remote (dtkn) successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

#shared_context "OLD - Delete service from remote repo" do |dtk_common, service_module_name, namespace|
#  it "deletes #{service_module_name} service with #{namespace} namespace from remote repo" do
#    service_deleted = dtk_common.delete_service_from_remote(service_module_name, namespace)
#    service_deleted.should eq(true)
#  end
#end