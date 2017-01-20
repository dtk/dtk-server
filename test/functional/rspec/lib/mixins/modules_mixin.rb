module ModulesMixin
  def module_exists_on_remote?(module_name, module_version)
    puts "Check module exist on remote:", "-------------------------------"
    modules_exists = false

    query_string_hash = {
      :detail_to_include => ['remotes', 'versions'],
      :rsa_pub_key => self.ssh_key,
    }
    query_params_hash = query_string_hash.map { |k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}" }.join('&')
    
    modules_list = send_request("/rest/api/v1/modules/remote_modules?#{query_params_hash}", {}, 'get')   
    pretty_print_JSON(modules_list)

    if modules_list['data'].empty?
      raise Exception, 'Unable to get module list from remote'
    else
      modules_list['data'].each do |cmp|
        if ((cmp['display_name'].include? module_name) && (cmp['versions'].include? module_version))
          modules_exists = true
          break
        end
      end
    end
    puts ""
    return modules_exists
  end
end