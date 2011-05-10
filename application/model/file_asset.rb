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
          #TODO: replace with this after debugging          ret << dir
          ret << debug_order_dir(dir)
        end
        children = dir[:children] ||= Array.new
        set_hierrachical_file_struct!(children,file_asset,path[1..path.size-1])
      end
    end
    private
    #TODO: remove after using for testing
   def self.debug_order_dir(dir)
     ret = ActiveSupport::OrderedHash.new()
     [:model_name, :display_name, :children].each do |k|
       ret[k] = dir[k] if dir.has_key?(k)
     end
     ret
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

