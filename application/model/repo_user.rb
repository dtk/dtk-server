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

   private

    def self.create?(model_handle,name)
      create_from_row?(model_handle,name,{:display_name => name, :username => name})
    end


    def self.r8server_name()
      "r8server"
    end

    def self.client_name(username)
      "r8client-#{username}"
    end

    def self.get_by_repo_username(model_handle,username)
      sp_hash = {
        :cols => [:id,:username],
        :filter => [:eq,:username,username]
      }
      get_obj(model_handle,sp_hash)
    end
  end
end
