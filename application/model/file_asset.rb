# TODO: Marked for removal [Haris]
module DTK
  class FileAsset < Model
    # model apis
    def get_content
      # if content stored in db then return that
      if cache_content?()
        return self[:content] if self[:content]
      end
      update_object!(:path, :implementation_info)
      content = RepoManager.get_file_content(self, { implementation: self[:implementation] })
      if cache_content?()
        # TODO: determine whether makes sense to store newly gotten content in db or just do this if any changes
      end
      content
    end

    def update_content(content)
      if cache_content?()
        update(content: content)
      end
      update_object!(:path, :implementation_info)

      # TODO: trap parse errors and then do consitemncy check with meta
      config_agent_type = config_agent_type()
      file_path = self[:path]
      #      file_config_type, r8_parse = ConfigAgent.parse_given_file_content(config_agent_type,file_path,content)

      impl_obj = self[:implementation]
      RepoManager.update_file_content(self, content, { implementation: impl_obj })
      impl_obj.set_to_indicate_updated()

      # special processing if this the meta file
      if ModuleDSL.isa_dsl_filename?(self[:path])
        target_impl = self[:implementation]
        component_dsl = ModuleDSL.create_from_file_obj_hash(target_impl, self[:path], content)
        component_dsl.update_model()
      end
      impl_obj.create_pending_changes_and_clear_dynamic_attrs(self)
    end

    # returns sha of remote head
    def self.add_and_push_to_repo(impl_obj, type, path, content, opts = {})
      add(impl_obj, type, path, content, opts)
      sha_remote_head = RepoManager.push_implementation(implementation: impl_obj)
      sha_remote_head
    end
    def self.add(impl_obj, type, path, content, opts = {})
      hash = ret_create_hash(impl_obj, type, path, content)
      file_asset_mh = impl_obj.model_handle.create_childMH(:file_asset)
      new_file_asset_idh = create_from_row(file_asset_mh, hash)
      new_file_asset_obj = new_file_asset_idh.create_object().merge(hash)
      RepoManager.add_file(new_file_asset_obj, content, { implementation: impl_obj })
      unless opts[:is_metafile]
        impl_obj.create_pending_changes_and_clear_dynamic_attrs(new_file_asset_obj)
      end
    end

    def self.ret_create_hash(impl_obj, type, path, content = nil)
      file_name = (path =~ Regexp.new('/([^/]+$)')) ? Regexp.last_match(1) : path
      {
        type: type,
        ref: file_asset_ref(path),
        file_name: file_name,
        display_name: file_name,
        path: path,
        content: cache_content?() ? content : nil,
        implementation_implementation_id: impl_obj.id()
      }
    end

    def self.ret_hierrachical_file_struct(flat_file_assets)
      ret = []
      flat_file_assets.each { |f| set_hierrachical_file_struct!(ret, f) }
      ret
    end

    def self.set_hierrachical_file_struct!(ret, file_asset, path = nil)
      path ||= file_asset[:path].split('/')
      if path.size == 1
        ret << file_asset.merge(model_name: 'file_asset')
      else
        dir = ret.find { |x| x[:display_name] == path[0] && x[:model_name] == 'directory_asset' }
        unless dir
          dir = {
            model_name: 'directory_asset',
            display_name: path[0]
          }
          ret << dir
        end
        children = dir[:children] ||= []
        set_hierrachical_file_struct!(children, file_asset, path[1..path.size - 1])
      end
    end

    protected

    def config_agent_type
      update_object!(:type)
      case self[:type]
        when 'puppet_file' then :puppet
        when 'chef_file' then :chef
        else raise Error.new("Unexpected type (#{self[:type]})")
      end
    end

    private

   def self.file_asset_ref(path)
     path.gsub(Regexp.new('/'), '_')
   end

   def cache_content?
     self.class.cache_content?()
   end
   def self.cache_content?
     R8::Config[:file_asset][:cache_content]
   end
 end
end
