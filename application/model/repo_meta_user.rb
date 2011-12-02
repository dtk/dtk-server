module XYZ
  class RepoMetaUser < Model
    def self.create?(model_handle,ref)
      uri_id_handle = model_handle.createIDH(:uri => "/repo_meta_user/#{ref}")
      #TODO: wrong function because just returns a uri; when it exists
      create_simple_instance?(uri_id_handle)
    end
  end
end
