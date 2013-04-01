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