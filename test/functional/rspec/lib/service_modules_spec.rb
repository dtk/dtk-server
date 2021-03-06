require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context 'Import service module' do |service_module_name|
  it "imports #{service_module_name} service module from local filesystem to server" do
    puts 'Import service module:', '----------------------'
    pass = true
    value = `dtk-run service-module import #{service_module_name}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'exists already'))
    puts "Import of service module #{service_module_name} completed successfully!" if pass == true
    puts "Import of service module #{service_module_name} did not complete successfully!" if pass == false
    puts ''
    pass.should eq(true)
  end
end

shared_context 'Import remote service module' do |service_module_name|
  it "imports #{service_module_name} service module from remote repo" do
    puts 'Import remote service module:', '-----------------------------'
    pass = true
    value = `dtk-run service-module install #{service_module_name} --update-none -y`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'exists on client'))
    puts "Import of remote service module #{service_module_name} completed successfully!" if pass == true
    puts "Import of remote service module #{service_module_name} did not complete successfully!" if pass == false
    puts ''
    pass.should eq(true)
  end
end

shared_context 'NEG - Import remote service module' do |service_module_name|
  it "will not import #{service_module_name} service module from remote repo since there are referenced component modules on local filesystem which are not deleted" do
    puts 'NEG - Import remote service module:', '-----------------------------------'
    pass = false
    value = `dtk-run service-module install #{service_module_name} --update-none`
    puts value
    pass = true if (value.include? 'is not empty')
    puts "Import of remote service module #{service_module_name} did not complete successfully because of the referenced component module that exists on local filesystem!" if pass == true
    puts "Import of remote service module #{service_module_name} completed successfully which is not expected!" if pass == false
    puts ''
    pass.should eq(true)
  end
end

shared_context 'Check service module imported on local filesystem' do |service_module_filesystem_location, service_module_name|
  it "checks that #{service_module_name} service module is imported on local filesystem on location #{service_module_filesystem_location}" do
    puts 'Check service module imported on local filesystem:', '--------------------------------------------------'
    pass = false
    `ls #{service_module_filesystem_location}/#{service_module_name}`
    pass = true if $?.exitstatus == 0
    if (pass == true)
      puts "Service module #{service_module_name} imported on local filesystem successfully!"
    else
      puts "Service module #{service_module_name} was not imported on local filesystem successfully!"
    end
    puts ''
    pass.should eq(true)
  end
end

shared_context 'Check component modules in service module' do |dtk_common, service_module_name, components_list_to_check|
  it "verifies that all component modules #{components_list_to_check.inspect} exist in #{service_module_name} service module" do
    components_exist = dtk_common.check_component_modules_in_service_module(service_module_name, components_list_to_check)
    components_exist.should eq(true)
  end
end

shared_context 'List all service modules' do |dtk_common, service_module_name|
  it "verifies that #{service_module_name} service module exists on server" do
    service_module_exists = dtk_common.check_if_service_module_exists(service_module_name)
    service_module_exists.should eq(true)
  end
end

shared_context 'NEG - List all service modules' do |dtk_common, service_module_name|
  it "verifies that #{service_module_name} service module does not exist on server" do
    service_module_exists = dtk_common.check_if_service_module_exists(service_module_name)
    service_module_exists.should eq(false)
  end
end

shared_context 'List all service modules on remote' do |service_module_name, namespace|
  it "verifies that #{service_module_name} service module exists on remote" do
    puts 'List all service modules on remote:', '-----------------------------------'
    pass = false
    value = `dtk-run service-module list --remote`
    puts value
    pass = true if value.include? "#{namespace}/#{service_module_name}"
    puts "List of service modules on remote contains service module #{service_module_name} on namespace #{namespace}" if pass == true
    puts "List of service modules on remote does not contain service module #{service_module_name} on namespace #{namespace}" if pass == false
    puts ''
    pass.should eq(true)
  end
end

shared_context 'Export service module' do |service_module_name, namespace|
  it "exports #{service_module_name} service module to #{namespace} namespace on remote repo" do
    puts 'Export service module to remote:', '--------------------------------'
    pass = false
    service_module = service_module_name.split(':').last
    value = `dtk-run service-module #{service_module_name} publish #{namespace}/#{service_module}`
    puts value
    pass = true if value.include? 'Status: OK'
    puts "Publish of #{service_module} service module to #{namespace} namespace has been completed successfully!" if pass == true
    puts "Publish of #{service_module} service module to #{namespace} namespace did not complete successfully!" if pass == false
    puts ''
    pass.should eq(true)
  end
end

shared_context 'Check if assembly belongs to the service module' do |dtk_common, service_module_name, assembly_name|
  it "verifes that #{assembly_name} assembly is part of the #{service_module_name} service module" do
    assembly_exists_in_service_module = dtk_common.check_if_service_module_contains_assembly(service_module_name, assembly_name)
    assembly_exists_in_service_module.should eq(true)
  end
end

shared_context 'Delete service module' do |dtk_common, service_module_name|
  it "deletes #{service_module_name} service module" do
    service_module_deleted = dtk_common.delete_service_module(service_module_name)
    service_module_deleted.should eq(true)
  end
end

shared_context 'Delete service module from local filesystem' do |service_module_filesystem_location, service_module_name|
  it "deletes #{service_module_name} service module from local filesystem" do
    puts 'Delete service module from local filesystem:', '--------------------------------------------'
    pass = false
    value = `rm -rf #{service_module_filesystem_location}/#{service_module_name}`
    pass = !value.include?('cannot remove')
    puts "Service module #{service_module_name} deleted from local filesystem successfully!" if pass == true
    puts "Service module #{service_module_name} was not deleted from local filesystem successfully!" if pass == false
    puts ''
    pass.should eq(true)
  end
end

shared_context 'Delete service module from remote repo' do |service_module_name, namespace|
  it "deletes #{service_module_name} service module with #{namespace} namespace from remote repo" do
    puts 'Delete service module from remote (dtkn):', '-----------------------------------------'
    pass = false
    value = `dtk-run service-module delete-from-catalog #{namespace}/#{service_module_name} -y`
    pass = true if (!value.include?('error') || !value.include?('cannot remove'))
    puts "Service module #{service_module_name} deleted from remote (dtkn) successfully!" if pass == true
    puts "Service module #{service_module_name} was not deleted from remote (dtkn) successfully!" if pass == false
    puts ''
    pass.should eq(true)
  end
end

shared_context 'List service modules with filter' do |dtk_common, namespace|
  it "gets all modules from namespace #{namespace}" do
    service_modules_retrieved = dtk_common.list_service_modules_with_filter(namespace)
    service_modules_retrieved.should eq(true)
  end
end

shared_context 'NEG - List service modules with filter' do |dtk_common, namespace|
  it "returns empty list of service modules because there are no service modules in namespace #{namespace}" do
    service_modules_retrieved = dtk_common.list_service_modules_with_filter(namespace)
    service_modules_retrieved.should eq(false)
  end
end

shared_context 'List service modules with filter on remote' do |dtk_common, namespace|
  it "gets all modules from namespace #{namespace} on remote" do
    service_modules_retrieved = dtk_common.list_remote_service_modules_with_filter(namespace)
    service_modules_retrieved.should eq(true)
  end
end

shared_context 'NEG - List service modules with filter on remote' do |dtk_common, namespace|
  it "returns empty list of service modules because there are no service modules in namespace #{namespace} on remote" do
    service_modules_retrieved = dtk_common.list_remote_service_modules_with_filter(namespace)
    service_modules_retrieved.should eq(false)
  end
end

shared_context 'Create service module on local filesystem' do |service_module_filesystem_location, service_module_name, file_to_copy_location, file_name, assembly_name|
  it "creates service module #{service_module_name} on local filesystem" do
    puts "Create service module on local filesystem", "----------------------------------------"
    pass = false
      `mkdir -p #{service_module_filesystem_location}/#{service_module_name}/assemblies`
      `cp #{file_to_copy_location} #{service_module_filesystem_location}/#{service_module_name}/assemblies/`
      `mv #{service_module_filesystem_location}/#{service_module_name}/assemblies/#{file_name} #{service_module_filesystem_location}/#{service_module_name}/assemblies/#{assembly_name}.dtk.assembly.yaml`
    value = `ls #{service_module_filesystem_location}/#{service_module_name}/assemblies/#{assembly_name}.dtk.assembly.yaml`
    puts value
    pass = value.include?("#{assembly_name}.dtk.assembly.yaml")
    puts ''
    expect(pass).to eq(true)
  end
end


shared_context 'Push local service module changes to server' do |service_module_name, file_for_change|
  it "pushes #{service_module_name} service module changes from local filesystem to server with changes on file #{file_for_change}" do
    puts 'Push clone changes to server:', '-----------------------------'
    pass = false
    value = `dtk-run service-module #{service_module_name} push`
    puts value
    pass = value.include?('Status: OK')
    puts 'Clone changes pushed to server successfully!' if pass == true
    puts 'Clone changes were not pushed to server successfully!' if pass == false
    puts ''
    pass.should eq(true)
  end
end

shared_context 'NEG - Push local service module changes to server' do |service_module_name, fail_message, expected_error_message|
  it "pushes #{service_module_name} service module changes from local filesystem to server but fails - reason: #{fail_message}" do
      puts 'NEG - Push clone changes to server:', '-----------------------------------'
      fail = false
      value = `dtk-run service-module #{service_module_name} push`
      puts value
      fail = value.include?(expected_error_message)
      puts ''
      fail.should eq(true)
    end
end

shared_context 'Push to remote changes for service module' do |service_module_name|
  it "pushes #{service_module_name} service module changes from server to repoman" do
    puts 'Push to remote service module changes:', '-----------------------------------'
    pass = false
    value = `dtk-run service-module #{service_module_name} push-dtkn`
    puts value
    pass = value.include?('Status: OK')
    puts 'Push to remote passed successfully!' if pass == true
    puts 'Push to remote didnt pass successfully!' if pass == false
    puts ''
    pass.should eq(true)
  end
end

shared_context 'Pull-dtkn service module' do |service_module_name|
  it "pulls latest content for #{service_module_name} from repoman" do
    puts 'Pull-dtkn service module:', '----------------------------'
    pass = false
    value = `dtk-run service-module #{service_module_name} pull-dtkn`
    puts value
    pass = true unless value.include? 'ERROR'
    puts "Service module #{service_module_name} pulled from repoman successfully!" if pass == true
    puts "Service module #{service_module_name} was not pulled from repoman successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Clone service module' do |dtk_common, service_module_name|
  it "clones service module #{service_module_name}" do
    service_module_cloned = dtk_common.clone_service_module(service_module_name)
    expect(service_module_cloned).to eq(true)
  end
end

shared_context 'NEG - Clone service module' do |dtk_common, service_module_name|
  it "does not clone service module #{service_module_name}" do
    service_module_version_cloned = dtk_common.clone_service_module(service_module_name)
    expect(service_module_cloned).to eq(false)
  end
end

shared_context 'Add assembly.yaml file' do |service_module_filesystem_location, assembly_location, file_for_change_location, assembly_name|
  it 'adds #{assembly_name} file' do
    puts 'Add #{assembly_name} file:', '---------------------------'
    pass = false
    current_path = `pwd`
      `cd #{service_module_filesystem_location}/;git pull;cd #{current_path}`
      `cp #{file_for_change_location} #{service_module_filesystem_location}/#{assembly_location}/#{assembly_name}`
      `cd #{service_module_filesystem_location}/#{assembly_location};mv *assembly.yaml #{assembly_name}`
    value = `ls #{service_module_filesystem_location}/#{assembly_location}/#{assembly_name}`
    pass = !value.include?('No such file or directory')
    puts 'assembly.yaml has been added!' if pass == true
    puts 'assembly.yaml has not been added!' if pass == false
    puts ''
    pass.should eq(true)
  end
end
