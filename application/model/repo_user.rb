module XYZ
  class RepoUser < Model
    def self.create_r8server?(model_handle)
      create?(model_handle,r8server_name())
    end

    def self.create_r8client?(model_handle,username)
      create?(model_handle,client_name(username))
    end

    #TODO: stub that gets all repo users
    def self.authorized_users(model_handle)
      get_objs(model_handle, :cols => [:id,:username]).map{|r|r[:username]}
    end

    #ssh_rsa_pub_key.nil? means that expected that key already exists in the gitolite admin db 
    def self.add_repo_user_for_session_user?(repo_user_type,ssh_rsa_pub_key=nil)
      repo_users = get_all_repo_users_for_session_user(:type => repo_user_type)
      if ssh_rsa_pub_key
        return false if repo_users.find{|r|r[:ssh_rsa_pub_key] == ssh_rsa_pub_key}
      else
        case repo_users.size
        when 0
        when 1
          return false
        else
          raise Error.new("Unexpected to have multiple matches of repo user type (#{repo_user_type})")
        end
      end
      
      repo_username,index =  ret_new_repo_username_and_index(repo_user_type,repo_users)
      create(model_handle_for_session_user(),type,repo_username,index,ssh_rsa_pub_key)
    end

   private
    
    def self.get_all_repo_users_for_session_user(filter_keys={})
      sp_hash = {
        :cols => [:id,:username,:type,:index,:ssh_rsa_pub_key]
      }
      unless filter_keys.empty?
        filter_list = filter_keys.map{|k,v|[:eq,k,v]}
        sp_hash[:filter] = (filter_list.size == 1 ? filter_list.first : ([:and] + filter_list))
      end
      get_objs(model_handle_for_session_user(),sp_hash)
    end


    #returns [new_repo_username,new_index]
    def ret_new_repo_username_and_index(type,existing_matches)
      max = 0
      existing_matches.each do |m|
        if m[:index] > max
          max = m[:index]
        end
      end
      new_index = max+1
      suffix = (new_index == 1 ? "" : "-#{new_index.to_s}")

      username = CurrentSession.new.get_user_object()[:username]
      new_repo_username = "dtk-#{type}-#{username}#{suffix}"
      [new_repo_username,new_index]
    end

    def self.model_handle_for_session_user()
      user_obj = CurrentSession.new.get_user_object()
      user_obj.id_handle().createMH(:repo_user)
    end


#TODO: deprecate?
    def self.get_by_repo_username(model_handle,username)
      sp_hash = {
        :cols => [:id,:username],
        :filter => [:eq,:username,username]
      }
      get_obj(model_handle,sp_hash)
    end

#TODO: deprecate? below
    def self.create?(model_handle,name)
      create_from_row?(model_handle,name,{:display_name => name, :username => name})
    end

    def self.r8server_name()
      "r8server"
    end

    def self.client_name(username)
      "r8client-#{username}"
    end
  end
end
