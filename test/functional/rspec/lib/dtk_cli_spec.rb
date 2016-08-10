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

shared_context 'List assemblies' do |module_name, assembly_name, dtk_common|
  it "checks that assembly: #{assembly_name} exists as part of module: #{module_name}" do
    puts 'List assemblies:', '----------------------'
    assembly_found = dtk_common.check_module_for_assembly(module_name, assembly_name)
    expect(assembly_found).to eq(true)
  end
end

shared_context 'Stage assembly from module' do |module_name, assembly_name, service_name|
  it "stages assembly #{assembly_name} from module #{module_name}" do
    puts 'Stage assembly from module', '-------------------------'
    pass = true
    value = `dtk service stage -m #{module_name} -n #{service_name} #{assembly_name}`
    puts value
    pass = false if value.include? 'ERROR'
    puts "Assembly #{assembly_name} is staged successfully!" if pass == true
    puts "Assembly #{assembly_name} did not stage successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Converge service instance' do |service_location, dtk_common, service_instance|
  it "converges new instance" do
    puts 'Converge service instance', '-------------------------'
    pass = true
    service_location = service_location + service_instance
    value = `cd #{service_location} && dtk service converge && cd -`
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
    value = `dtk service destroy --purge -d #{service_location} -y`
    puts value
    pass = false if value.include? 'ERROR'
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Uninstall module' do |module_name|
  it "uninstalls #{module_name} module from server" do
    puts 'Uninstall module:', '----------------------'
    pass = true
    value = `dtk module uninstall -m #{module_name} -y`
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