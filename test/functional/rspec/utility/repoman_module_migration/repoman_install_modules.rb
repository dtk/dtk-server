# This test script is used to install modules from repoman

require './lib/dtk_common'

selected_modules = YAML.load(File.open(File.dirname(__FILE__) + "/module_list.yaml"))['modules']

ssh_key_location = '~/.ssh/id_rsa.pub'
output_directory = '/tmp'

common = Common.new('','')
common.ssh_key = `cat #{ssh_key_location}`.strip

params_hash = { 
  :detail_to_include=>['remotes','versions'],
  :rsa_pub_key=>common.ssh_key,
}
query_params_string = params_hash.map { |k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}" }.join('&')
modules = common.send_request("/rest/api/v1/modules/remote_modules?#{query_params_string}", {}, 'get')
returned_modules = modules['data'].map { |x| { name: x['display_name'], versions: x['versions']} }

returned_modules.each do |md|
  if selected_modules.include? md[:name]
    puts "Found module #{md[:name]} on repoman"
    module_name = md[:name].gsub(/\//,'_')

    puts "Installing it in local machine on: #{output_directory}/#{module_name}"

    puts module_name
    `mkdir #{output_directory}/#{module_name}`
    md[:versions].each do |vs|
      `mkdir #{output_directory}/#{module_name}/#{vs}`
      puts "Installing module: #{md[:name]} with version: #{vs}"
      puts "---------------------------------------------------"
      puts `dtk module install -d #{output_directory}/#{module_name}/#{vs} -v #{vs} --skip-server #{md[:name]}`
      puts ""
    end
  end
end