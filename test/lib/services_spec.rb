require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

STDOUT.sync = true

shared_context "Create service" do |dtk_common, service_name|
  it "creates new service module #{service_name}" do
    service_created = dtk_common.create_new_service(service_name)
    service_created.should eq(true)
  end
end

shared_context "Import service" do |service_name|
  it "imports #{service_name} service from local filesystem to server" do
    puts "Import service:", "---------------"
    pass = false
    value = `dtk service import #{service_name}`
    pass = true if ((!value.include? "[ERROR]") || (!value.include? "exists already"))
    puts "Import of service #{service_name} completed successfully!" if pass == true
    puts "Import of service #{service_name} did not complete successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Import remote service" do |dtk_common, service_name|
  it "imports #{service_name} service from remote repo" do
    puts "Import remote service:", "---------------------"
    pass = false
    value = `dtk service import-dtkn #{service_name} -y`
    pass = true if ((!value.include? "[ERROR]") || (!value.include? "exists on client"))
    puts "Import of remote service #{service_name} completed successfully!" if pass == true
    puts "Import of remote service #{service_name} did not complete successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "NEG - Import remote service" do |dtk_common, service_name|
  it "will not import #{service_name} service from remote repo since there are referenced modules on local filesystem which are not deleted" do
    puts "NEG - Import remote service:", "----------------------------"
    pass = false
    value = `dtk service import-dtkn #{service_name}`
    pass = true if (value.include? "exists on client")
    puts "Import of remote service #{service_name} did not complete successfully because of the referenced module that exists on local filesystem!" if pass == true
    puts "Import of remote service #{service_name} completed successfully which is not expected!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Check service imported on local filesystem" do |service_filesystem_location, service_name|
  it "checks that #{service_name} service is imported on local filesystem on location #{service_filesystem_location}" do
    puts "Check service imported on local filesystem:", "-------------------------------------------"
    pass = false
    `ls #{service_filesystem_location}/#{service_name}`
    pass = true if $?.exitstatus == 0
    if (pass == true)
      puts "Service #{service_name} imported on local filesystem successfully!" 
    else
      puts "Service #{service_name} was not imported on local filesystem successfully!"
    end
    puts ""
    pass.should eq(true)
  end
end

shared_context "Check component modules in service" do |dtk_common, service_name, components_list_to_check|
  it "verifies that all component modules #{components_list_to_check.inspect} exist in #{service_name} service" do
    components_exist = dtk_common.check_component_modules_in_service(service_name, components_list_to_check)
    components_exist.should eq(true)
  end
end

shared_context "List all services" do |dtk_common, service_name|
  it "verifies that #{service_name} service exists on server" do
    service_exists = dtk_common.check_if_service_exists(service_name)
    service_exists.should eq(true)
  end
end

shared_context "NEG - List all services" do |dtk_common, service_name|
  it "verifies that #{service_name} service does not exist on server" do
    service_exists = dtk_common.check_if_service_exists(service_name)
    service_exists.should eq(false)
  end
end

shared_context "List all services on remote" do |dtk_common, service_name, namespace|
  it "verifies that #{service_name} service exists on remote" do
    service_exists = dtk_common.check_if_service_exists_on_remote(service_name, namespace)
    service_exists.should eq(true)
  end
end

shared_context "Export service" do |dtk_common, service_name, namespace|
  it "exports #{service_name} service to #{namespace} namespace on remote repo" do
    service_exported = dtk_common.export_service_to_remote(service_name, namespace)
    service_exported.should eq(true)
  end
end

shared_context "Check if assembly template belongs to the service" do |dtk_common, service_name, assembly_template_name|
  it "verifes that #{assembly_template_name} assembly template is part of the #{service_name} service" do
    template_exists_in_service = dtk_common.check_if_service_contains_assembly_template(service_name, assembly_template_name)
    template_exists_in_service.should eq(true)
  end
end

shared_context "Delete service" do |dtk_common, service_name|
  it "deletes #{service_name} service module" do
    service_deleted = dtk_common.delete_service(service_name)
    service_deleted.should eq(true)
  end
end

shared_context "Delete service from local filesystem" do |service_filesystem_location, service_name|
  it "deletes #{service_name} service module from local filesystem" do
    puts "Delete service from local filesystem:", "-------------------------------------"
    pass = false
    value = `rm -rf #{service_filesystem_location}/#{service_name}`
    pass = !value.include?("cannot remove")
    puts "Service #{service_name} deleted from local filesystem successfully!" if pass == true
    puts "Service #{service_name} was not deleted from local filesystem successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Delete service from remote repo" do |dtk_common, service_name, namespace|
  it "deletes #{service_name} service with #{namespace} namespace from remote repo" do
    service_deleted = dtk_common.delete_service_from_remote(service_name, namespace)
    service_deleted.should eq(true)
  end
end