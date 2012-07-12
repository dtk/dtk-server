module XYZ
  class FileAsset < Model
    #model apis
    def get_content()
      #if content stored in db then return that
      return self[:content] if self[:content]
      update_object!(:path,:implementation_info)
      content = RepoManager.get_file_content(self,{:implementation => self[:implementation]})
      #TODO: determine whether makes sense to store newly gotten content in db or just do this if any changes
      content
    end

    def update_content(content)
      update(:content => content)
      update_object!(:path,:implementation_info)

      #TODO: trap parse errors and then do consitemncy check with meta
      config_agent_type = config_agent_type()
      file_path = self[:path]
#      file_config_type, r8_parse = ConfigAgent.parse_given_file_content(config_agent_type,file_path,content)

      impl_obj = self[:implementation]
      RepoManager.update_file_content(self,content,{:implementation => impl_obj})
      impl_obj.set_to_indicate_updated()

      #special processing if this the meta file
      if r8_meta = ComponentMetaFile.isa?(self,content)
        r8_meta.update_model()
      end
      impl_obj.create_pending_changes_and_clear_dynamic_attrs(self)
    end

    def self.add(impl_obj,type,path,content)
      hash = create_hash(impl_obj,type,path,content)
      file_asset_mh = impl_obj.model_handle.createMH(:file_asset)
      new_file_asset_idh = create_from_row(file_asset_mh,hash)
      new_file_asset_obj = new_file_asset_idh.create_object().merge(hash)
      RepoManager.add_file(new_file_asset_obj,content,{:implementation => impl_obj})
      impl_obj.create_pending_changes_and_clear_dynamic_attrs(new_file_asset_obj)
    end

    def self.create_hash(impl_obj,type,path,content=nil)
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
          ret << dir
        end
        children = dir[:children] ||= Array.new
        set_hierrachical_file_struct!(children,file_asset,path[1..path.size-1])
      end
    end

   protected
    def config_agent_type()
      update_object!(:type)
      case self[:type]
        when "puppet_file" then :puppet
        when "chef_file" then :chef
        else raise Error.new("Unexpected type (#{self[:type]})")
      end
    end

  private
   def self.file_asset_ref(path)
     path.gsub(Regexp.new("/"),"_")
   end
 end
end

