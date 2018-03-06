# This test script is used to install modules from repoman

require './lib/dtk_common'

output_directory = ARGV[0]
environment = ARGV[1]

selected_modules = nil
if environment == "prod"
  selected_modules = YAML.load(File.open(File.dirname(__FILE__) + "/prod_repoman_module_list.yaml"))['modules']
else
  selected_modules = YAML.load(File.open(File.dirname(__FILE__) + "/test_repoman_module_list.yaml"))['modules']
end

ssh_key_location = '~/.ssh/id_rsa.pub'
output = `ls #{output_directory}`
`mkdir -p #{output_directory}` if output.include? "No such file or directory"

common = Common.new('','')
common.ssh_key = `cat #{ssh_key_location}`.strip

params_hash = { 
  :detail_to_include=>['remotes','versions'],
  :rsa_pub_key=>common.ssh_key,
}
query_params_string = params_hash.map { |k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}" }.join('&')
modules = common.send_request("/rest/api/v1/modules/remote_modules?#{query_params_string}", {}, 'get')
returned_modules = modules['data'].map { |x| { name: x['display_name'], versions: x['versions']} }

selected_modules.each do |sm|
  mod = returned_modules.select { |hash| hash[:name] == sm }.first
  
  unless mod.nil?
    puts "Found module #{sm} on repoman"
    module_name = sm.gsub(/\//,'_')

    puts "Installing it in local machine on: #{output_directory}/#{module_name}"
    puts module_name
    output = `ls #{output_directory}/#{module_name}`
    if ((output.include? "No such file or directory") || (!output.include? "\n"))
      `mkdir #{output_directory}/#{module_name}` 
      mod[:versions].each do |vs|
        `mkdir #{output_directory}/#{module_name}/#{vs}`
        puts "Installing module: #{sm} with version: #{vs}..."
        result = `dtk module install -d #{output_directory}/#{module_name}/#{vs} -v #{vs} --skip-server #{sm}`
        `rm -rf #{output_directory}/#{module_name}/#{vs}` if result.include? "ERROR"
        puts ""
      end
    end
    puts "Content installed for module #{module_name}:"
    puts "--------------------------------------------"
    puts `tree -L 2 #{output_directory}/#{module_name}`
  end
end