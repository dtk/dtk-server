require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context 'Check if component module version exists on server' do |dtk_common, component_module_name, version_name|
  it "checks that component module #{component_module_name} with version #{version_name} exists on server" do
    component_module_version_exists = dtk_common.check_component_module_version(component_module_name, version_name)
    expect(component_module_version_exists).to eq(true)
  end
end

shared_context 'NEG - Check if component module version exists on server' do |dtk_common, component_module_name, version_name|
  it "checks that component module #{component_module_name} with version #{version_name} does not exist on server" do
    component_module_version_exists = dtk_common.check_component_module_version(component_module_name, version_name)
    expect(component_module_version_exists).to eq(false)
  end
end

shared_context 'Check if component module version exists on remote' do |dtk_common, component_module_name, version_name|
  it "checks that component module #{component_module_name} with version #{version_name} exists on remote" do
    component_module_version_exists = dtk_common.check_component_module_remote_versions(component_module_name, version_name)
    expect(component_module_version_exists).to eq(true)
  end
end

shared_context 'NEG - Check if component module version exists on remote' do |dtk_common, component_module_name, version_name|
  it "checks that component module #{component_module_name} with version #{version_name} does not exist on remote" do
    component_module_version_exists = dtk_common.check_component_module_remote_versions(component_module_name, version_name)
    expect(component_module_version_exists).to eq(false)
  end
end

shared_context 'Set attribute on versioned component' do |dtk_common, component_module_name, version_name, attribute_name, attribute_value|
	it "sets attribute value #{attribute_value} for attribute #{attribute_name}" do
		attribute_set = dtk_common.set_attribute_on_versioned_component(component_module_name, component_name, attribute_name, attribute_value, version_name)
		expect(attribute_set).to eq(true)
	end
end

shared_context 'Add versioned component to service' do |dtk_common, namespace, component_name, version_name, service_name, node_name|
	it "adds component #{component_name} with version #{version_name} to service #{service_name} on node #{node_name}" do
		component_added = dtk_common.add_versioned_component_to_service(namespace, component_name, version_name, service_name, node_name)
		expect(component_added).to eq(true)
	end
end

shared_context 'NEG - Add versioned component to service' do |dtk_common, namespace, component_name, version_name, service_name, node_name|
	it "does not addd component #{component_name} with version #{version_name} since it does not exist" do
		component_added = dtk_common.add_versioned_component_to_service(namespace, component_name, version_name, service_name, node_name)
		expect(component_added).to eq(false)
	end
end

shared_context 'Publish versioned component module' do |dtk_common, component_module_name, version_name|
	it "publish/push component module #{component_module_name} with version #{version_name}" do
		component_module_published = dtk_common.publish_component_module_version(component_module_name, version_name)
		expect(component_module_published).to eq(true)
	end
end

shared_context 'NEG - Publish versioned component module' do |dtk_common, component_module_name, version_name|
	it "does not publish/push component module #{component_module_name} since this version #{version_name} does not exist" do
		component_module_published = dtk_common.publish_component_module_version(component_module_name, version_name)
		expect(component_module_published).to eq(false)
	end
end

shared_context 'Create component module version' do |dtk_common, component_module_name, version_name|
	it "creates component module #{component_module_name} version #{version_name}" do
		component_module_version_created = dtk_common.create_component_module_version(component_module_name, version_name)
		expect(component_module_version_created).to eq(true)
	end
end

shared_context 'NEG - Create component module version' do |dtk_common, component_module_name, version_name|
	it "does ntot create component module #{component_module_name} version #{version_name}" do
		component_module_version_created = dtk_common.create_component_module_version(component_module_name, version_name)
		expect(component_module_version_created).to eq(true)
	end
end

shared_context 'Delete component module version' do |dtk_common, component_module_name, version_name|
	it "deletes component module #{component_module_name} version #{version_name}" do
		component_module_version_deleted = dtk_common.delete_component_module_version(component_module_name, version_name)
		expect(component_module_version_deleted).to eq(true)
	end
end

shared_context 'NEG - Delete component module version' do |dtk_common, component_module_name, version_name|
	it "does not delete component module #{component_module_name} version #{version_name}" do
		component_module_version_deleted = dtk_common.delete_component_module_version(component_module_name, version_name)
		expect(component_module_version_deleted).to eq(false)
	end
end

shared_context 'Delete remote component module version' do |dtk_common, component_module_name, component_module_namespace, version_name|
	it "deletes remote component module #{component_module_name} version #{version_name}" do
		remote_component_module_version_deleted = dtk_common.delete_remote_component_module_version(component_module_name, component_module_namespace, version_name)
		expect(remote_component_module_version_deleted).to eq(true)
	end
end

shared_context 'NEG - Delete remote component module version' do |dtk_common, component_module_name, version_name|
	it "does not delete remote component module #{component_module_name} version #{version_name}" do
		remote_component_module_version_deleted = dtk_common.delete_remote_component_module_version(component_module_name, component_module_namespace, version_name)
		expect(remote_component_module_version_deleted).to eq(false)
	end
end

shared_context 'Clone component module version' do |dtk_common, component_module_name, version_name|
	it "clones component module #{component_module_name} version #{version_name}" do
		component_module_version_cloned = dtk_common.clone_component_module_version(component_module_name, version_name)
		expect(component_module_version_cloned).to eq(true)
	end
end

shared_context 'NEG - Clone component module version' do |dtk_common, component_module_name, version_name|
	it "does not clone component module #{component_module_name} version #{version_name}" do
		component_module_version_cloned = dtk_common.clone_component_module_version(component_module_name, version_name)
		expect(component_module_version_cloned).to eq(false)
	end
end

shared_context 'Install component module version' do |component_module_name, component_module_namespace, version_name|
	it 'installs component module #{component_module_namespace}/#{component_module_name} version #{version_name} from remote' do
		puts "Install component module version from remote:", "---------------------------------------------"
	    pass = true
	    value = `dtk component-module install #{component_module_namespace}/#{component_module_name} -v #{version_name}`
	    puts value
	    pass = false if ((value.include? 'ERROR') || (value.include? 'exists on client') || (value.include? 'denied') || (value.include? 'Conflicts with existing server local module'))
	    puts "Install of component module #{component_module_name} #{version_name} completed successfully!" if pass == true
	    puts "Install of component module #{component_module_name} #{version_name} completed successfully" if pass == false
	    puts ''
	    expect(pass).to eq(true)
	end
end


shared_context 'NEG - Install component module version' do |dtk_common, component_module_name, component_module_namespace, version_name|
	it "does not install component module #{component_module_namespace}/#{component_module_name} version #{version_name} from remote" do
		puts 'Install component module version from remote:', '---------------------------------------------'
	    pass = true
	    value = `dtk component-module install #{component_module_namespace}/#{component_module_name} -v #{version_name}`
	    puts value
	    pass = true if ((value.include? 'ERROR') || (value.include? 'exists on client') || (value.include? 'denied') || (value.include? 'Conflicts with existing server local module'))
	    puts "Install of component module #{component_module_name} #{version_name} was not successfull!" if pass == true
	    puts "Install of component module #{component_module_name} #{version_name} was successfull even though it should not!" if pass == false
	    puts ''
	    expect(pass).to eq(true)
	end
end

shared_context 'Delete all component module versions' do |dtk_common, component_module_name|
	it "deletes all component module #{component_module_name} versions" do
		component_module_versions_deleted = dtk_common.delete_all_component_module_versions(component_module_name)
		expect(component_module_versions_deleted).to eql(true)
	end
end

shared_context 'NEG - Delete all component module versions' do |dtk_common, component_module_name|
	it "does not delete all component module #{component_module_name} versions" do
		component_module_versions_deleted = dtk_common.delete_all_component_module_versions(component_module_name)
		expect(component_module_versions_deleted).to eql(false)
	end
end

shared_context 'Delete all local component module versions' do |component_module_filesystem_location, component_module_name|
	it "deletes all local versions of component module #{component_module_name}" do
		puts "Delete all local component module versions:", '-------------------------------------------'
    	passed = false
    	delete_versions_output = `rm -rf #{component_module_filesystem_location}/#{component_module_name}*`
    	passed = !delete_versions_output.include?('cannot remove')
    	puts "Component module #{component_module_name} versions deleted from local filesystem successfully!" if passed == true
    	puts "Component module #{component_module_name} versions were not deleted from local filesystem successfully!" if passed == false
    	puts ''
    	expect(passed).to eql(true)
	end
end

shared_context 'NEG - Delete all local component module versions' do |component_module_filesystem_location, component_module_name|
	it "does not delete all local versions of component module #{component_module_name}" do
		puts "Delete all local component module versions:", '-------------------------------------------'
    	passed = false
    	delete_versions_output = `rm -rf #{component_module_filesystem_location}/#{component_module_name}*`
    	passed = !delete_versions_output.include?('cannot remove')
    	puts "Component module #{component_module_name} versions deleted from local filesystem successfully!" if passed == true
    	puts "Component module #{component_module_name} versions were not deleted from local filesystem successfully!" if passed == false
    	puts ''
    	expect(passed).to eql(false)
	end
end