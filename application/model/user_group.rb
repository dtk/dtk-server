module XYZ
  class UserGroup < Model
    def self.all_groupname
      'all'
    end

    def self.private_groupname(username)
      "user-#{username}"
    end

    def self.get_all_group(model_handle)
      get_by_groupname(model_handle,all_groupname())
    end

    def self.get_private_group(model_handle,username)
      get_by_groupname(model_handle,private_groupname(username))
    end

    def self.get_by_groupname(model_handle,groupname)
      sp_hash = {
        cols: [:id, :groupname],
        filter: [:eq, :groupname,groupname]
      }
      get_obj(model_handle,sp_hash)
    end
  end
end
