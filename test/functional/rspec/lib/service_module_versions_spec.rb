require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context 'Check if service module version exists on server' do |dtk_common, service_module_name, version_name|
  it "checks that service module #{service_module_name} with version #{version_name} exists on server" do
    service_module_version_exists = dtk_common.check_service_module_version(service_module_name, version_name)
    expect(service_module_version_exists).to eq(true)
  end
end

shared_context 'NEG - Check if service module version exists on server' do |dtk_common, service_module_name, version_name|
  it "checks that service module #{service_module_name} with version #{version_name} does not exist on server" do
    service_module_version_exists = dtk_common.check_service_module_version(service_module_name, version_name)
    expect(service_module_version_exists).to eq(false)
  end
end

shared_context 'Check if service module version exists on remote' do |dtk_common, service_module_name, version_name|
  it "checks that service module #{service_module_name} with version #{version_name} exists on remote" do
    service_module_version_exists = dtk_common.check_service_module_remote_versions(service_module_name, version_name)
    expect(service_module_version_exists).to eq(true)
  end
end

shared_context 'NEG - Check if service module version exists on remote' do |dtk_common, service_module_name, version_name|
  it "checks that service module #{service_module_name} with version #{version_name} does not exist on remote" do
    service_module_version_exists = dtk_common.check_service_module_remote_versions(service_module_name, version_name)
    expect(service_module_version_exists).to eq(false)
  end
end

shared_context 'Publish versioned service module' do |dtk_common, service_module_name, remote_service_module_name, version_name|
	it "publish/push service module #{service_module_name} with version #{version_name}" do
		puts "Publish service module version to remote:", "-------------------------------------------"
	    pass = false
	    module_name = service_module_name.split(':')[1] #exract 'module_name' from string 'namespace:module_name'
	    value = `dtk service-module #{service_module_name} publish #{module_name} -v #{version_name}`
	    puts value
	    pass = true if (value.include? 'Status: OK')
	    puts "Publish of service module #{service_module_name} #{version_name} completed successfully!" if pass == true
	    puts "Publish of service module #{service_module_name} #{version_name} was not successfully" if pass == false
	    puts ''
	    expect(pass).to eq(true)
	end
end

shared_context 'NEG - Publish versioned service module' do |dtk_common, service_module_name, remote_service_module_name, version_name|
	it "does not publish/push service module #{service_module_name} since this version #{version_name} does not exist" do
		puts "Publish service module version to remote:", "-------------------------------------------"
	    pass = true
	    module_name = service_module_name.split(':')[1] #exract 'module_name' from string 'namespace:module_name'
	    value = `dtk service-module #{service_module_name} publish #{module_name} -v #{version_name}`
	    puts value
	    pass = false if (value.include? 'Status: OK')
	    puts "Publish of service module #{service_module_name} #{version_name} was successfully, even though it should be!y!" if pass == false
	    puts "Publish of service module #{service_module_name} #{version_name} was not successfully" if pass == true
	    puts ''
	    expect(pass).to eq(true)
	end
end
shared_context 'Create service module version' do |dtk_common, service_module_name, version_name|
	it "creates service module #{service_module_name} version #{version_name}" do
		service_module_version_created = dtk_common.create_service_module_version(service_module_name, version_name)
		expect(service_module_version_created).to eq(true)
	end
end

shared_context 'NEG - Create service module version' do |dtk_common, service_module_name, version_name|
	it "does ntot create service module #{service_module_name} version #{version_name}" do
		service_module_version_created = dtk_common.create_service_module_version(service_module_name, version_name)
		expect(service_module_version_created).to eq(false)
	end
end

shared_context 'Delete service module version' do |dtk_common, service_module_name, version_name|
	it "deletes service module #{service_module_name} version #{version_name}" do
		service_module_version_deleted = dtk_common.delete_service_module_version(service_module_name, version_name)
		expect(service_module_version_deleted).to eq(true)
	end
end

shared_context 'NEG - Delete service module version' do |dtk_common, service_module_name, version_name|
	it "does not delete service module #{service_module_name} version #{version_name}" do
		service_module_version_deleted = dtk_common.delete_service_module_version(service_module_name, version_name)
		expect(service_module_version_deleted).to eq(false)
	end
end

shared_context 'Delete remote service module version' do |dtk_common, service_module_name, service_module_namespace, version_name|
	it "deletes remote service module #{service_module_name} version #{version_name}" do
		remote_service_module_version_deleted = dtk_common.delete_remote_service_module_version(service_module_name, service_module_namespace, version_name)
		expect(remote_service_module_version_deleted).to eq(true)
	end
end

shared_context 'NEG - Delete remote service module version' do |dtk_common, service_module_name, version_name|
	it "does not delete remote service module #{service_module_name} version #{version_name}" do
		remote_service_module_version_deleted = dtk_common.delete_remote_service_module_version(service_module_name, service_module_namespace, version_name)
		expect(remote_service_module_version_deleted).to eq(false)
	end
end

shared_context 'Clone service module version' do |dtk_common, service_module_name, version_name|
	it "clones service module #{service_module_name} version #{version_name}" do
		service_module_version_cloned = dtk_common.clone_service_module_version(service_module_name, version_name)
		expect(service_module_version_cloned).to eq(true)
	end
end

shared_context 'NEG - Clone service module version' do |dtk_common, service_module_name, version_name|
	it "does not clone service module #{service_module_name} version #{version_name}" do
		service_module_version_cloned = dtk_common.clone_service_module_version(service_module_name, version_name)
		expect(service_module_version_cloned).to eq(false)
	end
end

shared_context 'Install service module version' do |service_module_name, service_module_namespace, version_name|
	it 'installs service module #{service_module_namespace}/#{service_module_name} version #{version_name} from remote' do
		puts "Install service module version from remote:", "---------------------------------------------"
	    pass = true
	    value = `dtk service-module install #{service_module_namespace}/#{service_module_name} -v #{version_name} --update-none -y`
	    puts value
	    pass = false if ((value.include? 'ERROR') || (value.include? 'exists on client') || (value.include? 'denied') || (value.include? 'Conflicts with existing server local module'))
	    puts "Install of service module #{service_module_name} #{version_name} completed successfully!" if pass == true
	    puts "Install of service module #{service_module_name} #{version_name} completed successfully" if pass == false
	    puts ''
	    expect(pass).to eq(true)
	end
end

shared_context 'NEG - Install service module version' do |dtk_common, service_module_name, service_module_namespace, version_name|
	it "does not install service module #{service_module_namespace}/#{service_module_name} version #{version_name} from remote" do
		puts 'Install service module version from remote:', '---------------------------------------------'
	    pass = true
	    value = `dtk service-module install #{service_module_namespace}/#{service_module_name} -v #{version_name} --update-none -y`
	    puts value
	    pass = true if ((value.include? 'ERROR') || (value.include? 'exists on client') || (value.include? 'denied') || (value.include? 'Conflicts with existing server local module'))
	    puts "Install of service module #{service_module_name} #{version_name} was not successfull!" if pass == true
	    puts "Install of service module #{service_module_name} #{version_name} was successfull even though it should not!" if pass == false
	    puts ''
	    expect(pass).to eq(true)
	end
end

shared_context 'Delete all service module versions' do |dtk_common, service_module_name|
	it "deletes all service module #{service_module_name} versions" do
		service_module_versions_deleted = dtk_common.delete_all_service_module_versions(service_module_name)
		expect(service_module_versions_deleted).to eql(true)
	end
end

shared_context 'NEG - Delete all service module versions' do |dtk_common, service_module_name|
	it "does not delete all service module #{service_module_name} versions" do
		service_module_versions_deleted = dtk_common.delete_all_service_module_versions(service_module_name)
		expect(service_module_versions_deleted).to eql(false)
	end
end

shared_context 'Delete all local service module versions' do |service_module_filesystem_location, service_module_name|
	it "deletes all local versions of service module #{service_module_name}" do
		puts "Delete all local service module versions:", '-------------------------------------------'
    	passed = false
    	delete_versions_output = `rm -rf #{service_module_filesystem_location}/#{service_module_name}*`
    	passed = !delete_versions_output.include?('cannot remove')
    	puts "Service module #{service_module_name} versions deleted from local filesystem successfully!" if passed == true
    	puts "Service module #{service_module_name} versions were not deleted from local filesystem successfully!" if passed == false
    	puts ''
    	expect(passed).to eql(true)
	end
end

shared_context 'NEG - Delete all local service module versions' do |service_module_filesystem_location, service_module_name|
	it "does not delete all local versions of service module #{service_module_name}" do
		puts "Delete all local service module versions:", '-------------------------------------------'
    	passed = false
    	delete_versions_output = `rm -rf #{service_module_filesystem_location}/#{service_module_name}*`
    	passed = !delete_versions_output.include?('cannot remove')
    	puts "Service module #{service_module_name} versions deleted from local filesystem successfully!" if passed == true
    	puts "Service module #{service_module_name} versions were not deleted from local filesystem successfully!" if passed == false
    	puts ''
    	expect(passed).to eql(false)
	end
end

shared_context 'Check if service module verison is exists locally' do |service_module_filesystem_location, service_module_name, service_module_version|
	it "checks that service module version exists on local filesystem" do
		puts 'Check service module version exists on local filesystem:', '--------------------------------------------------'
    	pass = false
    	`ls #{service_module_filesystem_location}/#{service_module_name}-#{service_module_version}`
    	pass = true if $?.exitstatus == 0
    	if (pass == true)
      		puts "Service module #{service_module_name} version #{service_module_version} exists on local filesystem!"
    	else
    	  	puts "Service module #{service_module_name} version #{service_module_version} does not exists on local filesystem!"
    	end
   	 	puts ''
    	expect(pass).to eql(true)
	end
end

shared_context 'NEG - Check if service module verison is exists locally' do |service_module_filesystem_location, service_module_name, service_module_version|
	it "checks that service module version does not exist on local filesystem" do
		puts 'Check service module version does not exist on local filesystem:', '--------------------------------------------------'
    	pass = false
    	`ls #{service_module_filesystem_location}/#{service_module_name}-#{service_module_version}`
    	pass = true if $?.exitstatus == 0
    	if (pass == true)
      		puts "Service module #{service_module_name} version #{service_module_version} exists on local filesystem, but it shouldn't!"
    	else
    	  	puts "Service module #{service_module_name} version #{service_module_version} does not exists on local filesystem!"
    	end
   	 	puts ''
    	expect(pass).to eql(false)
	end
end
