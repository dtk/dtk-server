module XYZ
  class RepoUser < Model
    #TODO: stub that gets all repo users
    def self.authorized_users(model_handle)
      get_objs(model_handle, :cols => [:id,:username]).map{|r|r[:username]}
    end

    #ssh_rsa_pub_key.nil? means that expected that key already exists in the gitolite admin db 
    def self.add_repo_user?(repo_user_type,repo_user_mh,ssh_rsa_pub_key=nil)
      repo_users = get_existing_repo_users(repo_user_mh,:type => repo_user_type.to_s)
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
      create(repo_user_mh,repo_user_type,repo_username,index,ssh_rsa_pub_key)
      true
    end

   private
    
    def self.get_existing_repo_users(repo_user_mh,filter_keys={})
      sp_hash = {
        :cols => [:id,:username,:type,:index,:ssh_rsa_pub_key]
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

    def self.create(model_handle,type,repo_username,index,ssh_rsa_pub_key)
      create_row = {
        :ref => repo_username,
        :display_name => repo_username,
        :username => repo_username,
        :index => index
      }
      if ssh_rsa_pub_key
        create_row[:ssh_rsa_pub_key] = ssh_rsa_pub_key
      end
      create_from_row(model_handle,create_row)
    end

#TODO: deprecate?
    def self.get_by_repo_username(model_handle,username)
      sp_hash = {
        :cols => [:id,:username],
        :filter => [:eq,:username,username]
      }
      get_obj(model_handle,sp_hash)
    end
  end
end
