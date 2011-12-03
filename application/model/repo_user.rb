module XYZ
  class RepoUser < Model
    def self.create?(model_handle,name)
      create_from_row?(model_handle,name,{:display_name => name, :username => name})
    end

    def self.get_by_username(model_handle,username)
      sp_hash = {
        :cols => [:id,:username],
        :filter => [:eq,:username,username]
      }
      get_obj(model_handle,sp_hash)
    end
  end
end
