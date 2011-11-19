module XYZ
  class RepoMeta < Model
    def self.get_all_repo_names()
      #TODO: stub until get info in db
      Dir.chdir(R8::Config[:repo][:base_directory]) do
        Dir["*"].reject{|item|File.file?(item)}
      end
    end

    def self.add_new_repo(model_handle,new_repo,create_context)
    end
  end
end
