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
    value = `dtk module install -d #{module_location} --update-deps`
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
    value = `dtk module install -d #{remote_module_location} -v #{version} --update-deps #{remote_module}`
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

shared_context 'List service instances after stage' do |dtk_common, service_instance|
  it "checks that service instance #{service_instance} exists" do
    puts 'List service instances after stage', '-------------------------------------'
    service_instance_found = dtk_common.check_if_service_instance_exists(service_instance)
    expect(service_instance_found).to eq(true)
  end
end

shared_context 'List service instances after delete' do |dtk_common, service_instance|
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
    value = `dtk module stage -d #{module_location} -n #{service_name} #{assembly_name}`
    puts value
    pass = false if value.include? 'ERROR'
    puts "Assembly #{assembly_name} is staged successfully!" if pass == true
    puts "Assembly #{assembly_name} is not staged successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Stage assembly from module to specific context' do |module_name, module_location, assembly_name, service_name, context_name|
  it "stages assembly #{assembly_name} from module #{module_name} in context #{context_name}" do
    puts 'Stage assembly from module to specific context', '---------------------------------------------'
    pass = true
    value = `dtk module stage --context #{context_name} -d #{module_location} -n #{service_name} #{assembly_name}`
    puts value
    pass = false if value.include? 'ERROR'
    puts "Assembly #{assembly_name} is staged to #{context_name} successfully!" if pass == true
    puts "Assembly #{assembly_name} is not staged to #{context_name} successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Stage context from module' do |context_name, context_location, assembly_name, service_name|
  it "stages context #{assembly_name} from module #{context_name}" do
    puts 'Stage context from module', '-------------------------'
    pass = true
    value = `dtk module stage --base -d #{context_location} -n #{service_name} #{assembly_name}`
    puts value
    pass = false if value.include? 'ERROR'
    puts "context #{assembly_name} is staged successfully!" if pass == true
    puts "context #{assembly_name} is not staged successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Set default context' do |context_service_name|
  it "sets context #{context_service_name} as default one" do
    puts 'Set default context', '------------------'
    pass = true
    value = `dtk service set-default-context #{context_service_name}`
    puts value
    pass = false if value.include? 'ERROR'
    puts "context #{context_service_name} is set as default one!" if pass == true
    puts "context #{context_service_name} is not set as default one!" if pass == false
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
      converge_info = dtk_common.check_task_status(service_instance)
      if converge_info[:pass]
        pass = true
        puts "Service instance is converged successfully!"
      else
        pass = false
        puts "Service instance was not converged successfully!"
      end
    end
    puts ''
    expect(pass).to eq(true), converge_info[:error]
  end
end

shared_context 'NEG - Converge service instance' do |service_location, dtk_common, service_instance, error_message|
  it "does not converge instance successfully" do
    puts 'NEG - Converge service instance', '------------------------------'
    pass = true
    service_location = service_location + service_instance
    value = `dtk service converge -d #{service_location}`
    puts value
    if value.include? error_message
      pass = false
      puts "Service instance was not converged successfully!"
    else
      converge_info = dtk_common.check_task_status(service_instance)
      if converge_info[:pass]
        pass = true
        puts "Service instance is converged successfully which was not expected!"
      else
        pass = false
        puts "Service instance was not converged successfully!"
      end
    end
    puts ''
    expect(pass).to eq(false), converge_info[:error]
  end
end

shared_context 'Converge service instance with breakpoint' do |service_location, dtk_common, service_instance, subtask_names_with_breakpoint|
  it "converges service instance and stops accordingly on the breakpoint in subtasks #{subtask_names_with_breakpoint}" do
    puts 'Converge service instance with breakpoint', '-------------------------------------'
    pass = true
    service_location = service_location + service_instance
    value = `dtk service converge -d #{service_location}`
    puts value
    if value.include? 'ERROR'
      pass = false
      puts "Service instance was not converged successfully!"
    else
      subtask_names_with_breakpoint.each do |subtask|
        debug_passed = dtk_common.check_task_status_with_breakpoint(service_instance, subtask)
        if debug_passed
          puts "Breakpoint on subtask #{subtask} works!"
        else
          pass = false
          puts "Breakpoint on subtask #{subtask} does not work!"
        end
      end

      converge_info = dtk_common.check_task_status(service_instance)
      if converge_info[:pass]
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

shared_context 'Get task status details' do |service_instance_location, stage_number, expected_output|
  it 'returns task status output and verifies it' do
    correct_task_action_outputs = false
    task_action_outputs = `dtk service task-status -m stream -d #{service_instance_location}`
    extracted_stage_output = task_action_outputs.split(stage_number).last.split("-----").first

    expected_output.each do |output|
      if (((extracted_stage_output.include? "RUN: #{output[:command]}") || (extracted_stage_output.include? "ADD: #{output[:command]}")) && ((extracted_stage_output.include? "STATUS: #{output[:status]}") || (output[:status].nil?)))
        puts 'Returned expected task action details!'
        if ((output[:stderr].nil?) && (!extracted_stage_output.include? 'STDERR'))
          correct_task_action_outputs = true
        elsif extracted_stage_output.include? "STDERR:\n  #{output[:stderr]}"
          correct_task_action_outputs = true
        else
          puts 'Returned stderr was not matched with expected one!'
          correct_task_action_outputs = false
          break
        end
      else
        puts 'Returned task action details is not the expected one!'
        correct_task_action_outputs = false
        break
      end
    end
    expect(correct_task_action_outputs).to eq(true)
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
      action_info = dtk_common.check_task_status(service_instance)
      if action_info[:pass]
        pass = true
        puts "Action was executed successfully!"
      else
        pass = false
        puts "Action was not executed successfully!"
      end
    end
    puts ''
    expect(pass).to eq(true), action_info[:error]
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
      stop_info = dtk_common.check_task_status(service_instance)
      if stop_info[:pass]
        pass = true
        puts "Service instance is stopped successfully!"
      else
        pass = false
        puts "Service instance was not stopped successfully!"
      end
    end
    puts ''
    expect(pass).to eq(true), stop_info[:error]
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

shared_context 'NEG - Uninstall service instance' do |service_location, service_instance, error_message|
  it "does not uninstall service instance" do
    puts 'NEG - Uninstall instance', '------------------------'
    pass = false
    service_location = service_location + service_instance
    value = `dtk service uninstall --purge -d #{service_location} -y`
    puts value
    pass = true if value.include? error_message
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
      delete_info = dtk_common.check_delete_task_status(service_instance)
      if delete_info[:pass]
        pass = true
        puts "Service instance is deleted successfully!"
      else
        pass = false
        puts "Service instance is not deleted successfully!"
      end
    end
    puts ''
    expect(pass).to eq(true), delete_info[:error]
  end
end

shared_context 'NEG - Delete service instance' do |service_location, service_instance, dtk_common, error_message|
  it "does not delete service instance content and triggers delete actions if any" do
    puts 'NEG - Delete instance', '-----------------------'
    pass = false
    service_location = service_location + service_instance
    value = `dtk service delete -d #{service_location} -y`
    pass = true if value.include? error_message
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Delete service instance with breakpoint' do |service_location, dtk_common, service_instance, delete_subtask_names_with_breakpoint|
  it "deletes service instance content and stops accordingly on the breakpoint in subtasks #{delete_subtask_names_with_breakpoint}" do
    puts 'Delete service instance with breakpoint', '---------------------------------------'
    pass = true
    service_location = service_location + service_instance
    value = `dtk service delete -d #{service_location} -y`
    puts value
    if value.include? 'ERROR'
      pass = false
      puts "Service instance was not deleted successfully!"
    else
      delete_subtask_names_with_breakpoint.each do |subtask|
        debug_passed = dtk_common.check_task_status_with_breakpoint(service_instance, subtask)
        if debug_passed
          puts "Breakpoint on delete subtask #{subtask} works!"
        else
          pass = false
          puts "Breakpoint on delete subtask #{subtask} does not work!"
        end
      end

      delete_info = dtk_common.check_delete_task_status(service_instance)
      if delete_info[:pass]
        puts "Service instance is deleted successfully!"
      else
        pass = false
        puts "Service instance was not deleted successfully!"
      end
    end
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Force delete service instance' do |service_location, service_instance, dtk_common|
  it "deletes service instance content with -f flag" do
    puts 'Force delete service instance', '-----------------------------------'
    pass = true
    service_location = service_location + service_instance
    value = `dtk service delete -d #{service_location} -f -y`
    if value.include? 'ERROR'
      pass = false
      puts "Service instance was not deleted successfully!"
    else
      delete_info = dtk_common.check_delete_task_status(service_instance)
      if delete_info[:pass]
        pass = true
        puts "Service instance is deleted successfully!"
        sleep 5
      else
        pass = false
        puts "Service instance is not deleted successfully!"
      end
    end
    puts ''
    expect(pass).to eq(true), delete_info[:error]
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

shared_context 'NEG - Uninstall module' do |module_name, module_location, error_message|
  it "does not uninstall #{module_name} module from server" do
    puts 'NEG - Uninstall module:', '-------------------------'
    pass = true
    value = `dtk module uninstall -d #{module_location} -y`
    puts value
    pass = false if ((value.include? error_message) || (value.include? "[ERROR]"))
    puts "Uninstall of module #{module_name} was completed successfully which is not expected!" if pass == true
    puts "Uninstall of module #{module_name} did not complete successfully which is expected!" if pass == false
    puts ''
    expect(pass).to eq(false)
  end
end

shared_context 'Add original content of dtk.module.yaml and module content' do |initial_module_location, module_location, original_dtk_module_name|
  it "copies initial module on location #{module_location}" do
    puts 'Add original content of dtk.module.yaml and module content', '----------------------------------------------------'
    pass = true
    `mkdir -p #{module_location} && cp -r #{initial_module_location}/* #{module_location}/ && mv #{module_location}/#{original_dtk_module_name} #{module_location}/dtk.module.yaml`
    value = system("ls #{module_location}/dtk.module.yaml")
    pass = false if value == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Replace original content of dtk.module.yaml with delta content' do |module_location, delta_module_content|
  it "updates content of dtk.module.yaml" do
    puts "Replace original content of dtk.module.yaml with delta content", "----------------------------------------------"
    pass = true
    `rm #{module_location}/dtk.module.yaml && mv #{module_location}/#{delta_module_content} #{module_location}/dtk.module.yaml`
    value = system("ls #{module_location}/dtk.module.yaml")
    pass = false if value == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Setup initial module on filesystem' do |initial_module_location, module_location|
  it "copies initial module on location #{module_location}" do
    puts 'Setup initial module on filesystem', '-------------------------------'
    pass = true
    filename = initial_module_location.split('/').last
    `mkdir -p #{module_location} && cp #{initial_module_location} #{module_location} && mv #{module_location}/#{filename} #{module_location}/dtk.module.yaml`
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

shared_context 'Delete module content on filesystem' do |module_location|
  it "deletes module contnet on location #{module_location}" do
    puts 'Delete module content on filesystem', '----------------------------------'
    pass = false
    `rm -rf #{module_location}/*`
    `rm -rf #{module_location}/.git`
    value = system("ls #{module_location}/ | grep dtk.module.yaml")
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
    `mv #{service_location}/*.yaml #{service_location}/dtk.service.yaml`
    value = `ls #{service_location}/dtk.service.yaml`
    pass = !value.include?('No such file or directory')
    puts 'dtk.service.yaml has been updated!' if pass == true
    puts 'dtk.service.yaml has not been updated!' if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context "Change content of dependency module in service instance on local filesystem" do |dependency_module_location, update_dependency_module_location|
  it "updates content of dependency module in service instance on local filesystem" do
    puts "Update content of dependency module in service instance on local filesystem", '------------------------------------------------------------------'
    pass = false
    `cp #{update_dependency_module_location} #{dependency_module_location}/`
    `rm -rf #{dependency_module_location}/dtk.nested_module.yaml`
    `mv #{dependency_module_location}/*.yaml #{dependency_module_location}/dtk.nested_module.yaml`
    value = `ls #{dependency_module_location}/dtk.nested_module.yaml`
    pass = !value.include?('No such file or directory')
    puts 'dtk.nested_module.yaml has been updated!' if pass == true
    puts 'dtk.nested_module.yaml has not been updated!' if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context "Check dependency module exists on service instance" do |dtk_common, service_name, service_location, module_name|
  it "checks that module #{module_name} exists as dependency on service instance #{service_name}" do
    puts "Check dependency module exists on service instance", "----------------------------------------------------"
    pass = false
    # todo: add content here
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

shared_context "NEG - Push module changes" do |module_name, module_location|
  it "does not push changes for module #{module_name}" do
    puts 'NEG - Push module changes', '-----------------------------'
    pass = true
    value = `dtk module push -d #{module_location}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'Cannot find a module DSL'))
    puts "Push of module #{module_name} was completed successfully which is not expected!" if pass == true
    puts "Push of module #{module_name} did not complete successfully which is expected!" if pass == false
    puts ''
    expect(pass).to eq(false)
  end
end

shared_context "Push-dtkn module changes" do |module_name, module_location|
  it "pushes changes for module #{module_name} to dtkn" do
    puts 'Push-dtkn module changes', '----------------------------'
    pass = true
    value = `dtk module push-dtkn -d #{module_location}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'Cannot find a module DSL'))
    puts "Push-dtkn of module #{module_name} was completed successfully!" if pass == true
    puts "Push-dtkn of module #{module_name} did not complete successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context "NEG - Push-dtkn module changes" do |module_name, module_location|
  it "does not push changes for module #{module_name} to dtkn" do
    puts 'NEG - Push-dtkn module changes', '-------------------------------'
    pass = true
    value = `dtk module push-dtkn -d #{module_location}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'Cannot find a module DSL'))
    puts "Push-dtkn of module #{module_name} was completed successfully which is not expected!" if pass == true
    puts "Push-dtkn of module #{module_name} did not complete successfully which is expected!" if pass == false
    puts ''
    expect(pass).to eq(false)
  end
end

shared_context "Publish module" do |module_name, module_location|
  it "publish module #{module_name} to dtkn" do
    puts 'Publish module changes', '--------------------------'
    pass = true
    value = `dtk module publish -d #{module_location}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'Cannot find a module DSL'))
    puts "Publish of module #{module_name} was completed successfully!" if pass == true
    puts "Publish of module #{module_name} did not complete successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context "NEG - Publish module" do |module_name, module_location|
  it "does not publish module #{module_name} to dtkn" do
    puts 'NEG - Publish module changes', '-----------------------------'
    pass = true
    value = `dtk module publish -d #{module_location}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'Cannot find a module DSL'))
    puts "Publish of module #{module_name} was completed successfully which is not expected!" if pass == true
    puts "Publish of module #{module_name} did not complete successfully which is expected!" if pass == false
    puts ''
    expect(pass).to eq(false)
  end
end

shared_context "NEG - Publish module with incorrect name" do |module_name, module_location|
  it "does not publish module #{module_name} to dtkn" do
    puts 'NEG - Publish module changes', '-----------------------------'
    pass = true
    value = `dtk module publish -d #{module_location}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'Cannot find a module DSL'))
    puts "Publish of module #{module_name} was completed successfully which is not expected!" if pass == true
    puts "Publish of module #{module_name} did not complete successfully which is expected!" if pass == false
    puts ''
    expect(pass).to eq(false)
  end
end

shared_context "Delete module from remote" do |dtk_common, module_name, module_version|
  it "deletes module #{module_name} with version #{module_version} from dtkn" do
    puts 'Delete module from remote', '-------------------------'
    pass = true
    value = `dtk module delete-from-dtkn -y -v #{module_version} #{module_name}`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'Cannot find a module DSL'))
    module_exists_on_repoman = dtk_common.module_exists_on_remote?(module_name, module_version)
    pass = false if module_exists_on_repoman == true
    puts "Delete of module #{module_name} from remote was completed successfully!" if pass == true
    puts "Delete of module #{module_name} from remote did not complete successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context "NEG - Delete module from remote" do |dtk_common, module_name, module_version|
  it "does not delete module #{module_name} with version #{module_version} from dtkn" do
    puts 'NEG - Delete module from remote', '------------------------------'
    pass = true
    value = `dtk module delete-from-dtkn -y -v #{module_version} #{module_name}`
    puts value
    pass = false if ((value.include? "Module '#{module_name}' does not exist on repo manager!") || (value.include? "Module '#{module_name}(#{module_version})' not found in the DTKN Catalog"))
    puts "Delete of module #{module_name} from remote was completed successfully which is not expected!" if pass == true
    puts "Delete of module #{module_name} from remote did not complete successfully which is expected!" if pass == false
    puts ''
    expect(pass).to eq(false)
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

shared_context 'NEG - Check attributes correct in service instance' do |dtk_common, service_name, attributes_to_check|
  it "verifies that attributes are not correct in service instance #{service_name}" do
    puts 'Check attributes correct in service instance', '-----------------------------------------------'
    attributes_exists = dtk_common.check_if_attributes_exists_in_service_instance(service_name, attributes_to_check)
    puts "Attributes exists and are correct on service instance #{service_name} which is not expected" if attributes_exists == true
    puts "Attributes does not exist or are not correct on service instance #{service_name} which is expected" if attributes_exists == false
    puts ''
    expect(attributes_exists).to eq(false)
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