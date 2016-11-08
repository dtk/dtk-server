require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

STDOUT.sync = true

shared_context 'Install module' do |module_name, module_location|
  it "installs #{module_name} module from local filesystem to server" do
    puts 'Install module:', '----------------------'
    pass = true
    value = `dtk module install -d #{module_location}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'exists already'))
    puts "Install of module #{module_name} was completed successfully!" if pass == true
    puts "Install of module #{module_name} did not complete successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Install module from dtkn' do |remote_module, remote_module_location, version|
  it "installs #{remote_module} module from dtkn to server" do
    puts 'Install module from dtkn:', '-----------------------------'
    pass = true
    value = `dtk module install -d #{remote_module_location} -v #{version} #{remote_module}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'exists already'))
    puts "Install of module #{remote_module} was completed successfully!" if pass == true
    puts "Install of module #{remote_module} did not complete successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'List assemblies' do |module_name, assembly_name, dtk_common|
  it "checks that assembly: #{assembly_name} exists as part of module: #{module_name}" do
    puts 'List assemblies:', '----------------------'
    assembly_found = dtk_common.check_module_for_assembly(module_name, assembly_name)
    expect(assembly_found).to eq(true)
  end
end

shared_context 'List service instances after stage' do |service_instance|
  it "checks that service instance #{service_instance} exists" do
    puts 'List service instances after stage', '-------------------------------------'
    service_instance_found = dtk_common.check_if_service_instance_exists(service_instance)
    expect(service_instance_found).to eq(true)
  end
end

shared_context 'List service instances after delete' do |service_instance|
  it "checks that service instance #{service_instance} does not exist" do
    puts 'List service instances after delete', '-------------------------------------'
    service_instance_found = dtk_common.check_if_service_instance_exists(service_instance)
    expect(service_instance_found).to eq(false)
  end
end

shared_context 'Stage assembly from module' do |module_name, module_location, assembly_name, service_name|
  it "stages assembly #{assembly_name} from module #{module_name}" do
    puts 'Stage assembly from module', '-------------------------'
    pass = true
    value = `dtk service stage -d #{module_location} -n #{service_name} #{assembly_name}`
    puts value
    pass = false if value.include? 'ERROR'
    puts "Assembly #{assembly_name} is staged successfully!" if pass == true
    puts "Assembly #{assembly_name} is not staged successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Stage assembly from module to specific target' do |module_name, module_location, assembly_name, service_name, target_name|
  it "stages assembly #{assembly_name} from module #{module_name} in target #{target_name}" do
    puts 'Stage assembly from module to specific target', '---------------------------------------------'
    pass = true
    value = `dtk service stage --parent #{target_name} -d #{module_location} -n #{service_name} #{assembly_name}`
    puts value
    pass = false if value.include? 'ERROR'
    puts "Assembly #{assembly_name} is staged to #{target_name} successfully!" if pass == true
    puts "Assembly #{assembly_name} is not staged to #{target_name} successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Stage target from module' do |target_name, target_location, assembly_name, service_name|
  it "stages target #{assembly_name} from module #{target_name}" do
    puts 'Stage target from module', '-------------------------'
    pass = true
    value = `dtk service stage --target -d #{target_location} -n #{service_name} #{assembly_name}`
    puts value
    pass = false if value.include? 'ERROR'
    puts "Target #{assembly_name} is staged successfully!" if pass == true
    puts "Target #{assembly_name} is not staged successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Set attribute' do |service_location, service_name, attribute_name, attribute_value|
  it "sets attribute for #{attribute_name}" do
    puts 'Set attribute', '---------------'
    pass = true
    service_location = service_location + service_name
    value = `dtk service set-attribute -d #{service_location} #{attribute_name} #{attribute_value}`
    puts value
    pass = false if value.include? 'ERROR'
    puts "Attribute #{attribute_name} is set correctly on #{service_name} service instance" if pass == true
    puts "Attribute #{attribute_name} is not set correctly on #{service_name} service instance" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Converge service instance' do |service_location, dtk_common, service_instance|
  it "converges new instance" do
    puts 'Converge service instance', '-------------------------'
    pass = true
    service_location = service_location + service_instance
    value = `dtk service converge -d #{service_location}`
    puts value
    if value.include? 'ERROR'
      pass = false
      puts "Service instance was not converged successfully!"
    else
      converge_succeeded = dtk_common.check_task_status(service_instance)
      if converge_succeeded
        pass = true
        puts "Service instance is converged successfully!"
      else
        pass = false
        puts "Service instance was not converged successfully!"
      end
    end
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Exec action/workflow' do |dtk_common, service_location, service_instance, action_name|
  it "executes action/workflow" do
    puts 'Execute action/workflow', '---------------------------'
    pass = true
    service_location = service_location + service_instance
    value = `dtk service exec -d #{service_location} #{action_name}`
    puts value
    if value.include? 'ERROR'
      pass = false
      puts "Action was not executed successfully!"
    else
      action_succeeded = dtk_common.check_task_status(service_instance)
      if action_succeeded
        pass = true
        puts "Action was executed successfully!"
      else
        pass = false
        puts "Action was not executed successfully!"
      end
    end
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Destroy service instance' do |service_location, service_instance|
  it "deletes and destroys service instance" do
    puts 'Destroy instance', '--------------------'
    pass = true
    service_location = service_location + service_instance
    value = `dtk service uninstall --purge -d #{service_location} -y`
    puts value
    pass = false if value.include? 'ERROR'
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Stop service instance' do |dtk_common, service_location, service_instance|
  it "stops service instance" do
    puts 'Stop service instance', '-------------------------'
    pass = true
    service_location = service_location + service_instance
    value = `dtk service stop -d #{service_location}`
    puts value
    if value.include? 'ERROR'
      pass = false
      puts "Service instance was not stopped successfully!"
    else
      # Missing task status output that reports on nodes being stopped
      stop_succeeded = dtk_common.check_task_status(service_instance)
      if stop_succeeded
        pass = true
        puts "Service instance is stopped successfully!"
      else
        pass = false
        puts "Service instance was not stopped successfully!"
      end
    end
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Uninstall service instance' do |service_location, service_instance|
  it "uninstalls service instance" do
    puts 'Uninstall instance', '--------------------'
    pass = true
    service_location = service_location + service_instance
    value = `dtk service uninstall --purge -d #{service_location} -y`
    puts value
    pass = false if value.include? 'ERROR'
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Delete service instance' do |service_location, service_instance, dtk_common|
  it "deletes service instance content and triggers delete actions if any" do
    puts 'Delete instance', '--------------------'
    pass = true
    service_location = service_location + service_instance
    value = `dtk service delete -d #{service_location} -y`
    if value.include? 'ERROR'
      pass = false
      puts "Service instance was not deleted successfully!"
    else
      delete_succeeded = dtk_common.check_delete_task_status(service_instance)
      if delete_succeeded
        pass = true
        puts "Service instance is deleted successfully!"
      else
        pass = false
        puts "Service instance is not deleted successfully!"
      end
    end
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Uninstall module' do |module_name, module_location|
  it "uninstalls #{module_name} module from server" do
    puts 'Uninstall module:', '----------------------'
    pass = true
    value = `dtk module uninstall -d #{module_location} -y`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'does not exist'))
    puts "Uninstall of module #{module_name} was completed successfully!" if pass == true
    puts "Uninstall of module #{module_name} did not complete successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Setup initial module on filesystem' do |initial_module_location, module_location|
  it "copies initial module on location #{module_location}" do
    puts 'Setup initial module on filesystem', '-------------------------------'
    pass = true
    filename = initial_module_location.split('/').last
    `mkdir #{module_location} && cp #{initial_module_location} #{module_location} && mv #{module_location}/#{filename} #{module_location}/dtk.module.yaml`
    value = system("ls #{module_location}/dtk.module.yaml")
    pass = false if value == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Delete initial module on filesystem' do |module_location|
  it "deletes initial module location #{module_location}" do
    puts 'Delete initial module on filesystem', '----------------------------------'
    pass = false
    `rm -rf #{module_location}`
    value = system("ls #{module_location}")
    pass = true if value == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context "Clone module on filesystem" do |module_name, module_location|
  it "clones module to local filesystem on location #{module_location}" do
    puts 'Clone module to filesystem', '---------------------------------'
    pass = true
    value = `dtk module clone #{module_name} #{module_location}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'does not exist'))
    puts "Clone of module #{module_name} was completed successfully!" if pass == true
    puts "Clone of module #{module_name} did not complete successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context "Change content of module on local filesystem" do |module_location, update_module_location|
  it "updates content of module on local filesystem" do
    puts "Update content of module on local filesystem", '----------------------------------------------'
    pass = false
    module_name = update_module_location.split("/").last
    `cp #{update_module_location} #{module_location}/`
    `mv #{module_location}/#{module_name} #{module_location}/dtk.module.yaml`
    value = `ls #{module_location}/dtk.module.yaml`
    pass = !value.include?('No such file or directory')
    puts 'dtk.module.yaml has been updated!' if pass == true
    puts 'dtk.module.yaml has not been updated!' if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context "Change content of service instance on local filesystem" do |service_location, update_service_location|
  it "updates content of service instance on local filesystem" do
    puts "Update content of service instance on local filesystem", '-----------------------------------------------------'
    pass = false
    `cp #{update_service_location} #{service_location}/`
    `rm -rf #{service_location}/dtk.service.yaml`
    `mv #{service_location}/* #{service_location}/dtk.service.yaml`
    value = `ls #{service_location}/dtk.service.yaml`
    pass = !value.include?('No such file or directory')
    puts 'dtk.service.yaml has been updated!' if pass == true
    puts 'dtk.service.yaml has not been updated!' if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context "Push module changes" do |module_name, module_location|
  it "pushes changes for module #{module_name}" do
    puts 'Push module changes', '-------------------------'
    pass = true
    value = `dtk module push -d #{module_location}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'Cannot find a module DSL'))
    puts "Push of module #{module_name} was completed successfully!" if pass == true
    puts "Push of module #{module_name} did not complete successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context "Push service instance changes" do |service_name, service_location|
  it "pushes changes for service instance #{service_name}" do
    puts 'Push service instance changes', '--------------------------------'
    pass = true
    value = `dtk service push -d #{service_location}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'Cannot find a module DSL'))
    puts "Push of service instance #{service_name} was completed successfully!" if pass == true
    puts "Push of service instance #{service_name} did not complete successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context "NEG - Push service instance changes" do |service_name, service_location|
  it "does not push changes for service instance #{service_name} successfully" do
    puts 'NEG - Push service instance changes', '--------------------------------'
    pass = true
    value = `dtk service push -d #{service_location}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'Cannot find a module DSL'))
    puts "Push of service instance #{service_name} was completed successfully which is not expected!" if pass == true
    puts "Push of service instance #{service_name} did not complete successfully!" if pass == false
    puts ''
    expect(pass).to eq(false)
  end
end

shared_context 'Check node exist in service instance' do |dtk_common, service_name, node_to_check|
  it "verifies that #{node_to_check} exists in service instance #{service_name}" do
    puts 'Check node exist in service instance', '-----------------------------------------------'
    node_exists = dtk_common.check_if_node_exists_in_service_instance(service_name, node_to_check)
    puts "Node #{node_to_check} exists on service instance #{service_name}" if node_exists == true
    puts "Node #{node_to_check} does not exist on service instance #{service_name}" if node_exists == false
    puts ''
    expect(node_exists).to eq(true)
  end
end

shared_context 'Check node group exist in service instance' do |dtk_common, service_name, node_group_to_check, cardinality|
  it "verifies that #{node_group_to_check} exists in service instance #{service_name}" do
    puts 'Check node group exist in service instance', '-----------------------------------------------'
    node_group_exists = dtk_common.check_if_node_group_exists_in_service_instance(service_name, node_group_to_check, cardinality)
    puts "Node group #{node_group_to_check} exists on service instance #{service_name}" if node_group_exists == true
    puts "Node group #{node_group_to_check} does not exist on service instance #{service_name}" if node_group_exists == false
    puts ''
    expect(node_group_exists).to eq(true)
  end
end

shared_context 'Check component exist in service instance' do |dtk_common, service_name, component_to_check|
  it "verifies that #{component_to_check} exists in service instance #{service_name}" do
    puts 'Check component exist in service instance', '-----------------------------------------------'
    component_exists = dtk_common.check_if_component_exists_in_service_instance(service_name, component_to_check)
    puts "Component #{component_to_check} exists on service instance #{service_name}" if component_exists == true
    puts "Component #{component_to_check} does not exist on service instance #{service_name}" if component_exists == false
    puts ''
    expect(component_exists).to eq(true)
  end
end

shared_context 'Check attributes correct in service instance' do |dtk_common, service_name, attributes_to_check|
  it "verifies that attributes exists and are correct in service instance #{service_name}" do
    puts 'Check attributes correct in service instance', '-----------------------------------------------'
    attributes_exists = dtk_common.check_if_attributes_exists_in_service_instance(service_name, attributes_to_check)
    puts "Attributes exists and are correct on service instance #{service_name}" if attributes_exists == true
    puts "Attributes does not exist or are not correct on service instance #{service_name}" if attributes_exists == false
    puts ''
    expect(attributes_exists).to eq(true)
  end
end

shared_context 'Check workflow exist in service instance' do |dtk_common, service_name, workflow_to_check|
  it "verifies that workflow exists in service instance #{service_name}" do
    puts 'Check workflow exists in service instance', '-----------------------------------------------'
    workflow_exists = dtk_common.check_if_action_exists_in_service_instance(service_name, workflow_to_check)
    puts "Workflow exists on service instance #{service_name}" if workflow_exists == true
    puts "Workflow does not exist on service instance #{service_name}" if workflow_exists == false
    puts ''
    expect(workflow_exists).to eq(true)
  end
end

shared_context 'NEG - Check node exist in service instance' do |dtk_common, service_name, node_to_check|
  it "verifies that #{node_to_check} does not exist in service instance #{service_name}" do
    puts 'NEG - Check node exist in service instance', '-----------------------------------------------'
    node_exists = dtk_common.check_if_node_exists_in_service_instance(service_name, node_to_check)
    puts "Node #{node_to_check} exists on service instance #{service_name}" if node_exists == true
    puts "Node #{node_to_check} does not exist on service instance #{service_name}" if node_exists == false
    puts ''
    expect(node_exists).to eq(false)
  end
end

shared_context 'NEG - Check node group exist in service instance' do |dtk_common, service_name, node_group_to_check, cardinality|
  it "verifies that #{node_group_to_check} does not exist in service instance #{service_name}" do
    puts 'NEG - Check node group exist in service instance', '-----------------------------------------------'
    node_group_exists = dtk_common.check_if_node_group_exists_in_service_instance(service_name, node_group_to_check, cardinality)
    puts "Node group #{node_group_to_check} exists on service instance #{service_name}" if node_group_exists == true
    puts "Node group #{node_group_to_check} does not exist on service instance #{service_name}" if node_group_exists == false
    puts ''
    expect(node_group_exists).to eq(false)
  end
end

shared_context 'NEG - Check component exist in service instance' do |dtk_common, service_name, component_to_check|
  it "verifies that #{component_to_check} does not exist in service instance #{service_name}" do
    puts 'NEG - Check component exist in service instance', '---------------------------------------------------'
    component_exists = dtk_common.check_if_component_exists_in_service_instance(service_name, component_to_check)
    puts "Component #{component_to_check} exists on service instance #{service_name}" if component_exists == true
    puts "Component #{component_to_check} does not exist on service instance #{service_name}" if component_exists == false
    puts ''
    expect(component_exists).to eq(false)
  end
end