module DTK
  class ServiceModule
    module SettingsMixin
     private
      SettingFilenamePathInfo = {
        :regexp => Regexp.new("^assemblies/([^/]+)/(.*)\.dtk\.settings\.(json|yaml)$"),
        :path_depth => 4
      }

      def create_setting_objects_from_dsl(project_idh,module_branch)
        ret = nil
        settings_to_add = Hash.new
        dangling_errors = ParsingError::DanglingComponentRefs::Aggregate.new(:error_cleanup => proc{error_cleanup()})
        setting_meta_file_paths(module_branch) do |meta_file,assembly_name|
          dangling_errors.aggregate_errors!()  do
            file_content = RepoManager.get_file_content(meta_file,module_branch)
            format_type = meta_file_format_type(meta_file)
            hash_content = Aux.convert_to_hash(file_content,format_type,:file_path => meta_file)||{}
            return hash_content if ParsingError.is_error?(hash_content)
            (settings_to_add[assembly_name] ||= Array.new) << hash_content
          end
        end
        if errors = dangling_errors.raise_error?(:do_not_raise => true)
          return errors
        end
        return ret if settings_to_add.empty?

        ndx_assembly_name_to_id = Assembly::Template.get_ndx_assembly_names_to_ids(project_idh,self,settings_to_add.keys)
        settings_to_add.each_pair do |assembly_name,hash_content_array|
          if assembly_id = ndx_assembly_name_to_id[assembly_name]
            assembly_idh = project_idh.createIDH(:model_name => :component, :id => assembly_id)
            create_settings_for_assembly(assembly_idh,hash_content_array)
          else
            Log.error("Unexpected that cannot find assembly for (#{assembly_name})")
          end
        end
        ret
      end

      def create_settings_for_assembly(assembly_idh,hash_content_array)
        db_update_hash = hash_content_array.inject(DBUpdateHash.new()) do |h,hash_content|
          h.merge(ret_settings_hash(assembly_idh,hash_content))
        end
        db_update_hash.mark_as_complete()
        Model.input_hash_content_into_model(assembly_idh,:service_setting => db_update_hash)
      end

      def ret_settings_hash(assembly_idh,hash_content)
        ref = hash_content['name']
        {
          ref => {
            :display_name => hash_content['name'],
            :node_bindings => hash_content['node_bindings'],
            :attribute_settings => hash_content['attribute_settings'],
            :component_component_id => assembly_idh.get_id()
          }
        }
      end

      def setting_meta_file_paths(module_branch,&block)
        setting_dsl_path_info = SettingFilenamePathInfo
        depth = setting_dsl_path_info[:path_depth]
        ret = RepoManager.ls_r(depth,{:file_only => true},module_branch)
        regexp = setting_dsl_path_info[:regexp]
        ret.reject!{|f|not (f =~ regexp)}
        ret_with_removed_variants(ret).each do |meta_file|
          unless assembly_name = (if meta_file =~ regexp then $1; end)
            raise Error.new("Cannot find assembly name")
          end
          block.call(meta_file,assembly_name)
        end
      end
    end
  end
end
