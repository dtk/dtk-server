require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

STDOUT.sync = true

shared_context 'Install module' do |module_name, dtk_cli_path|
  it "installs #{module_name} module from local filesystem to server" do
    puts 'Install module:', '----------------------'
    pass = true
    value = `#{dtk_cli_path}/bin/dtk module install`
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'exists already'))
    puts "Install of module #{module_name} was completed successfully!" if pass == true
    puts "Instlal of module #{module_name} did not complete successfully!" if pass == false
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

shared_context 'Push module' do |module_name, dtk_cli_path|
  it "push #{module_name} module changes from local filesystem to server" do
    puts 'Push module:', '----------------------'
    pass = true
    value = `#{dtk_cli_path}/bin/dtk module push`
    puts value
    pass = false if value.include? 'ERROR'
    puts "Push of module #{module_name} was completed successfully!" if pass == true
    puts "Push of module #{module_name} did not complete successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end

shared_context 'Delete module' do |module_name, dtk_cli_path|
  it "deletes #{module_name} module from server" do
    puts 'Delete module:', '----------------------'
    pass = true
    value = `#{dtk_cli_path}/bin/dtk module delete -y` # currently -y flag does not work
    puts value
    pass = false if ((value.include? 'ERROR') || (value.include? 'does not exist'))
    puts "Delete of module #{module_name} was completed successfully!" if pass == true
    puts "Delete of module #{module_name} did not complete successfully!" if pass == false
    puts ''
    expect(pass).to eq(true)
  end
end
