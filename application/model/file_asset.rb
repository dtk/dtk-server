module XYZ
  class FileAsset < Model
    #model apis
    def get_implementation_file_content()
      #if content stored in db then return that
      return self[:content] if self[:content]
      #TODO: can make more efficient to see if this object has the values that querying for an if so avoid db query
      sp_hash = {
        :cols => [:path,:implementation_info]
      }
      file_obj = get_objects_from_sp_hash(sp_hash).first
      repo_path = file_obj[:implementation][:repo_path] 
      #TODO: determine whether makes sense to store newly gotten content in db or just do this if any changes
      Repo.get_file_content(file_obj,repo_path)
    end
#stubs for methods
=begin
    def rename(new_name)
    end
    def delete()
    end
    def update_implementation_file_content()
    end

=end
  end
end

