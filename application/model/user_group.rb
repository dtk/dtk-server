module XYZ
  class UserGroup < Model
    def self.get_from_groupname(model_handle,groupname)
      sp_hash = {
        :cols => [:id, :groupname],
        :filter => [:eq, :groupname,groupname]
      }
      get_obj(model_handle,sp_hash)
    end
  end
end
