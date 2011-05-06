module XYZ
  class FileAsset < Model
    #model apis
    def get_content()
      #if content stored in db then return that
      return self[:content] if self[:content]
      #TODO: can make more efficient to see if this object has the values that querying for an if so avoid db query
      file_obj = get_objects_from_sp_hash({:cols => [:path,:implementation_info]}).first
      project = {:ref => "project1"} #TODO: stub until get the relevant project
      content = Repo.get_file_content(file_obj,{:implementation => file_obj[:implementation], :project => project})
      #TODO: determine whether makes sense to store newly gotten content in db or just do this if any changes
      content
    end

    def update_content(content)
      update(:content => content)
      #TODO: can make more efficient to see if this object has the values that querying for an if so avoid db query
      file_obj = get_objects_from_sp_hash({:cols => [:path,:implementation_info]}).first
      project = {:ref => "project1"} #TODO: stub until get the relevant project
      Repo.update_file_content(self,content,{:implementation => file_obj[:implementation], :project => project})
      file_obj[:implementation].create_pending_change_item(self)
    end

#stubs for methods
=begin
    def rename(new_name)
    end
    def delete()
    end
=end
  end
end

