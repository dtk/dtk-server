require 'uri'

module ModulesMixin
  def module_exists_on_remote?(module_name, module_version)
    puts "Check module exist on remote:", "-------------------------------"
    modules_exists = false
    ssh_key = URI.encode(self.ssh_key)
    
    modules_list = send_request("/rest/api/v1/modules/remote_modules?rsa_pub_key=#{ssh_key}", {}, 'get')   
    pretty_print_JSON(modules_list)

    if modules_list['data'].empty?
      raise Exception, 'Unable to get module list from remote'
    else
      modules_list['data'].each do |cmp|
        if cmp['display_name'].include? module_name && cmp['version'] == module_version
          modules_exists = true
          break
        end
      end
    end
    puts ""
    return modules_exists
  end
end