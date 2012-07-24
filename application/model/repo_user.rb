module XYZ
  class RepoUser < Model

    #TODO: stub that gets all repo users that are visbile; may restrict by filter on owner
    def self.authorized_users(model_handle)
      get_objs(model_handle, :cols => [:id,:username]).map{|r|r[:username]}
    end

    #ssh_rsa_pub_key.nil? means that expected that key already exists in the gitolite admin db 
    #returns an object or calls block (with new or existing object) 
    def self.add_repo_user?(repo_user_type,repo_user_mh,ssh_rsa_pub_key=nil)
      repo_users = get_existing_repo_users(repo_user_mh,:type => repo_user_type.to_s)
      if ssh_rsa_pub_key
        match = repo_users.find{|r|r[:ssh_rsa_pub_key] == ssh_rsa_pub_key}
        return match if match
      else
        case repo_users.size
         when 0
         when 1
          return repo_users.first
         else
          raise Error.new("Unexpected to have multiple matches of repo user type (#{repo_user_type})")
        end
      end
      
      repo_username,index =  ret_new_repo_username_and_index(repo_user_type,repo_users)
      if ssh_rsa_pub_key
        RepoManager.add_user(repo_username,ssh_rsa_pub_key,:noop_if_exists => true)
      end
      create_instance(repo_user_mh,repo_user_type,repo_username,index,ssh_rsa_pub_key)
    end

    def self.get_matching_repo_user(repo_user_mh,filters_keys)
      ret = nil
      repo_users = get_existing_repo_users(repo_user_mh,filters_keys)
      if repo_users.size > 1
        raise Error.new("Unexpected to have multiple matches of repo user when matching on (#{filters_keys.inspect})")
      end
      repo_users.first
    end

    def self.get_by_repo_username(model_handle,repo_username)
      sp_hash = {
        :cols => [:id,:username],
        :filter => [:eq,:username,repo_username]
      }
      get_obj(model_handle,sp_hash)
    end

    def has_direct_access?(module_model_name,opts={})
      direct_access_col = direct_access_col(module_model_name)
      update_object!(direct_access_col) unless opts[:donot_update]
      self[direct_access_col]
    end

    def any_direct_access_except?(module_model_name)
       case module_model_name
        when :component_module then has_direct_access?(:service_module)
        when :service_module then has_direct_access?(:component_module)
        else raise Error.new("Illegal module model name (#{module_model_name})")
      end
    end

    def update_direct_access(module_model_name,val)
      direct_access_col = direct_access_col(module_model_name)
      update(direct_access_col => val)
      self[direct_access_col] = val
      self
    end

   private
    def direct_access_col(module_model_name)
      case module_model_name
       when :component_module then :component_module_direct_access
       when :service_module then :service_module_direct_access
       else raise Error.new("Illegal module model name (#{module_model_name})")
      end
    end

    def self.get_existing_repo_users(repo_user_mh,filter_keys={})
      sp_hash = {
        :cols => [:id,:group_id,:username,:type,:index,:ssh_rsa_pub_key,:component_module_direct_access,:service_module_direct_access]
      }
      unless filter_keys.empty?
        filter_list = filter_keys.map{|k,v|[:eq,k,v]}
        sp_hash[:filter] = (filter_list.size == 1 ? filter_list.first : ([:and] + filter_list))
      end
      get_objs(repo_user_mh,sp_hash)
    end


    #returns [new_repo_username,new_index]
    def self.ret_new_repo_username_and_index(type,existing_matches)
      max = 0
      existing_matches.each do |m|
        if m[:index] > max
          max = m[:index]
        end
      end
      new_index = max+1
      suffix = (new_index == 1 ? "" : "-#{new_index.to_s}")

      username = CurrentSession.new.get_user_object()[:username]
      #TODO: temp until rename the server key
      if type == :system
        new_repo_username = "r8server"
      else
        new_repo_username = "dtk-#{type}-#{username}#{suffix}"
      end
      [new_repo_username,new_index]
    end

    def self.create_instance(model_handle,type,repo_username,index,ssh_rsa_pub_key)
      create_row = {
        :ref => repo_username,
        :display_name => repo_username,
        :username => repo_username,
        :index => index,
        :type => type.to_s
      }
      if ssh_rsa_pub_key
        create_row[:ssh_rsa_pub_key] = ssh_rsa_pub_key
      end
      new_idh = create_from_row(model_handle,create_row)
      new_idh.create_object.merge(create_row)
    end
  end
end
