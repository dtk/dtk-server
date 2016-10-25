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
    if version == 'master'
      value = `dtk module install -d #{remote_module_location} #{remote_module}`
      puts value
    else
      value = `dtk module install -d #{remote_module_location} -v #{version} #{remote_module}`
      puts value
    end
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
    value = `dtk service stage --target -d #{target_location} -n #{service_name} #{assembly_name} `
    puts value
    pass = false if value.include? 'ERROR'
    puts "Target #{assembly_name} is staged successfully!" if pass == true
    puts "Target #{assembly_name} is not staged successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Set attribute' do |service_location, target_service_name, attribute_name, attribute_value|
  it "sets attribute for #{attribute_name}" do
    puts 'Set attribute', '---------------'
    pass = true
    service_location = service_location + target_service_name
    value = `dtk service set-attribute -d #{service_location} #{attribute_name} #{attribute_value}`
    puts value
    pass = false if value.include? 'ERROR'
    puts "Attribute #{attribute_name} is set correctly on #{target_service_name} service instance" if pass == true
    puts "Attribute #{attribute_name} is not set correctly on #{target_service_name} service instance" if pass == false
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