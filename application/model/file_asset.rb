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

    def self.add(impl_obj,type,path,content)
      file_name = (path =~ Regexp.new("/([^/]+$)")) ? $1 : path
      hash = {
        :type => type,
        :ref => file_asset_ref(path),
        :file_name => file_name,
        :display_name => file_name,
        :path => path,
        :content => content,
        :implementation_implementation_id => impl_obj.id()
      }
      file_asset_mh = impl_obj.model_handle.createMH(:file_asset)
      new_file_asset_idh = create_from_rows(file_asset_mh,[hash]).first
      new_file_asset_obj = new_file_asset_idh.create_object().merge(hash)
      project = {:ref => "project1"} #TODO: stub until get the relevant project
      Repo.add_file(new_file_asset_obj,content,{:implementation => impl_obj, :project => project})
      impl_obj.create_pending_change_item(new_file_asset_obj)
    end
   private
    def self.file_asset_ref(path)
      path.gsub(Regexp.new("/"),"_")
    end
   public

    def self.ret_hierrachical_file_struct(flat_file_assets)
      ret = Array.new
      flat_file_assets.each{|f| set_hierrachical_file_struct!(ret,f)}
      ret
    end

    def self.set_hierrachical_file_struct!(ret,file_asset,path=nil)
      path ||= file_asset[:path].split("/")
      if path.size == 1
        ret << file_asset.merge(:model_name => "file_asset")
      else
        dir = ret.find{|x|x[:display_name] == path[0] and x[:model_name] == "directory_asset"}
        unless dir
          dir = {
            :model_name => "directory_asset",
            :display_name => path[0]
          }
          ret << dir
        end
        children = dir[:children] ||= Array.new
        set_hierrachical_file_struct!(children,file_asset,path[1..path.size-1])
      end
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

