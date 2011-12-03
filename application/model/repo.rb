module XYZ
  class Repo < Model
    def self.get_all_repo_names(model_handle)
      get_objs(model_handle,:cols => [:repo_name]).map{|r|r[:repo_name]}
    end

    def self.add_new_repo(model_handle,new_repo,create_context)
    end
  end
end
