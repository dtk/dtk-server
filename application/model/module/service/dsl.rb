module DTK
  class ServiceModule
    r8_nested_require('dsl','common')
    r8_nested_require('dsl','assembly_import')
    r8_nested_require('dsl','assembly_export')
    r8_nested_require('dsl','parser')
    r8_nested_require('dsl','parsing_error')
    r8_nested_require('dsl','settings')
    include SettingsMixin

    module DSLVersionInfo
      def self.default_integer_version()
        ret = R8::Config[:dsl][:service][:integer_version][:default]
        ret && ret.to_i
      end
      def self.version_to_integer_version(version,opts={})
        unless integer_version = VersionToIntegerVersion[version.to_s]
          error_msg = "Illegal version (#{version}) found in assembly dsl file"
          if file_path = opts[:file_path]
            error_msg += " (#{file_path})"
          end
          raise ErrorUsage.new(error_msg)
        end
        integer_version
      end

      def self.integer_version_to_version(integer_version)
        IntegerVersionToVersion[integer_version]
      end
      VersionToIntegerVersion  = {
        "0.9.1" => 3,
        "1.0.0" => 4
      }
      IntegerVersionToVersion = {
        1 => nil, #1 and 2 do not have a version stamped in file
        2 => nil,
        3 => "0.9.1",
        4 => "1.0.0"
      }
    end

    module DSLClassMixin
      def delete_assembly_dsl?(assembly_template_idh)
        sp_hash = {
          :cols => [:display_name, :module_branch],
          :filter => [:eq,:id,assembly_template_idh.get_id()]
        }
        assembly_template_mh = assembly_template_idh.createMH()
        ndx_module_branches = Hash.new
        Assembly::Template.get_objs(assembly_template_mh,sp_hash).each do |r|
          module_branch = r[:module_branch]
          assembly_name = r[:display_name]

          assembly_path = assembly_meta_filename_path(assembly_name,module_branch)
          is_legacy  = is_legacy_service_module_structure?(module_branch)

          # if not legacy structure, delete assembly_name.dtk.assembly.yaml file
          RepoManager.delete_file?(assembly_path,module_branch) unless is_legacy

          # raise Error.new("need to modify to componsate for fact that what is now needs to be deleted is files and possibly dir; these are assembly file (#{assembly_path}), plus possibly settings files")

          assembly_dir = assembly_meta_directory_path(assembly_name,module_branch)
          RepoManager.delete_directory?(assembly_dir,module_branch)

          ndx_module_branches[module_branch[:id]] ||= module_branch
        end
        ret = nil
        ndx_module_branches.each_value do |module_branch|
          RepoManager.push_changes(module_branch)
          if module_branch[:is_workspace]
            ret = module_branch.get_module_repo_info()
          end
        end
        ret
      end

      def assembly_meta_filename_path(assembly_name,module_branch)
        file_type = dsl_files_format_type()
        if is_legacy_service_module_structure?(module_branch)
          "assemblies/#{assembly_name}/assembly.#{file_type}"
        else
          "assemblies/#{assembly_name}.dtk.assembly.#{file_type}"
        end
      end

      def assembly_meta_directory_path(assembly_name,module_branch)
        "assemblies/#{assembly_name}"
      end

      def assembly_workflow_meta_filename_path(assembly_name,task_action)
        file_type = dsl_files_format_type()
        "assemblies/#{assembly_name}/workflows/#{task_action}.#{file_type}"
      end

      # returns [meta_files,regexp]
      def meta_files_and_regexp?(module_branch)
        meta_files,regexp,is_legacy_structure = meta_files_regexp_and_is_legacy?(module_branch)
        [meta_files,regexp]
      end

      def is_legacy_service_module_structure?(module_branch)
        meta_files,regexp,is_legacy_structure = meta_files_regexp_and_is_legacy?(module_branch)
        is_legacy_structure
      end

     private

      # returns [meta_files,regexp,is_legacy_structure]
      def meta_files_regexp_and_is_legacy?(module_branch)
        # determine if new structure or not
        is_legacy_structure = false
        meta_files,regexp = meta_files_and_regexp_aux?(AssemblyFilenamePathInfo,module_branch)
        if meta_files.empty?
          meta_files,regexp = meta_files_and_regexp_aux?(AssemblyFilenamePathInfoLegacy,module_branch)
          is_legacy_structure = !meta_files.empty?
        end
        [meta_files,regexp,is_legacy_structure]
      end

      AssemblyFilenamePathInfo = {
        :regexp => Regexp.new("^assemblies/(.*)\.dtk\.assembly\.(json|yaml)$"),
        :path_depth => 3
      }

      AssemblyFilenamePathInfoLegacy = {
        :regexp => Regexp.new("^assemblies/([^/]+)/assembly\.(json|yaml)$"),
        :path_depth => 3
      }

      def meta_file_assembly_name(meta_file_path)
        (meta_file_path.match(AssemblyFilenamePathInfo[:regexp])||[])[1] ||
        (meta_file_path.match(AssemblyFilenamePathInfoLegacy[:regexp])||[])[1] 
      end
      public :meta_file_assembly_name
 
      # returns [meta_files, regexp]
      def meta_files_and_regexp_aux?(assembly_dsl_path_info,module_branch)
        depth = assembly_dsl_path_info[:path_depth]
        meta_files = RepoManager.ls_r(depth,{:file_only => true},module_branch)
        regexp = assembly_dsl_path_info[:regexp]
        [meta_files.select{|f|f =~ regexp},regexp]
      end

      def dsl_files_format_type()
        format_type_default = R8::Config[:dsl][:service][:format_type][:default]
        case format_type_default
        when "json" then "json"
        when "yaml" then "yaml"
          else raise Error.new("Unexpected value for dsl.service.format_type.default: #{format_type_default}")
        end
      end
    end

    module DSLMixin
      # TODO: fix what update_model_from_dsl returns by looking at its usage
      def update_model_from_dsl(module_branch,opts={})
        module_branch.set_dsl_parsed!(false)

        component_module_refs = update_component_module_refs(module_branch,opts)
        return component_module_refs if ParsingError.is_error?(component_module_refs)

        v_namespaces = validate_module_ref_namespaces(module_branch,component_module_refs)
        return v_namespaces if ParsingError.is_error?(v_namespaces)

        parsed, component_module_refs = update_assemblies_from_dsl(module_branch,component_module_refs,opts)
        if new_commit_sha = component_module_refs.serialize_and_save_to_repo?()
          if opts[:ret_dsl_updated_info]
            msg = "The module refs file was updated by the server"
            opts[:ret_dsl_updated_info] = ModuleDSLInfo::UpdatedInfo.new(:msg => msg, :commit_sha => new_commit_sha)
          end
        end
        return parsed if ParsingError.is_error?(parsed)

        module_branch.set_dsl_parsed!(true)

        # return component modules required by this service module
        parsed.merge!(:component_module_refs => component_module_refs.component_modules)
        parsed
      end

     private
      def update_component_module_refs(module_branch,opts={})
        ModuleRefs::Parse.update_component_module_refs(ServiceModule,module_branch,opts)
      end

      # returns[ parsed,new_component_module_refs]
      def update_assemblies_from_dsl(module_branch,component_module_refs,opts={})
        ret_cmr = component_module_refs
        project_idh = get_project.id_handle()
        module_name = module_name()
        module_branch_idh = module_branch.id_handle()

        # check if service instances are using assembly template before changes
        service_instances = get_assembly_instances()
        validate_service_instance_references(service_instances, module_branch) unless service_instances.empty?

        assembly_import_helper = AssemblyImport.new(project_idh,module_branch,self,component_module_refs)
        aggregate_errors = ParsingError::Aggregate.new(:error_cleanup => proc{error_cleanup()})
        assembly_meta_file_paths(module_branch) do |meta_file,default_assembly_name|
          aggregate_errors.aggregate_errors!()  do
            file_content = RepoManager.get_file_content(meta_file,module_branch)
            format_type = meta_file_format_type(meta_file)
            opts.merge!(:file_path => meta_file,:default_assembly_name => default_assembly_name)

            hash_content = Aux.convert_to_hash(file_content,format_type,opts)||{}
            return [hash_content,ret_cmr] if ParsingError.is_error?(hash_content)

            # check if comp_name.dtk.assembly.yaml matches name in that file
            # only perform check for new service module structure
            unless self.class.is_legacy_service_module_structure?(module_branch)
              response = validate_name_for_assembly(meta_file,hash_content['name'])
              return [response,ret_cmr] if ParsingError.is_error?(response)
            end

            # check if assembly_wide_components exist and add them to assembly_wide node
            parse_assembly_wide_components!(hash_content)

            parsed = assembly_import_helper.process(module_name,hash_content,opts)
            return [parsed,ret_cmr] if ParsingError.is_error?(parsed)
          end
        end
        errors = aggregate_errors.raise_error?(:do_not_raise => true)
        return [errors,ret_cmr] if errors.is_a?(ParsingError)

        parsed = assembly_import_helper.import()

        if response = create_setting_objects_from_dsl(project_idh,module_branch)
          if ParsingError.is_error?(response)
            return [response,ret_cmr]
          end
        end

        if opts[:auto_update_module_refs]
          # TODO: should also update teh contents of component module refs
          ret_cmr = ModuleRefs.get_component_module_refs(module_branch)
        end

        [parsed,ret_cmr]
      end

      # signature is assembly_meta_file_paths(module_branch) do |meta_file,default_assembly_name|
      def assembly_meta_file_paths(module_branch, &block)
        meta_files,regexp = ServiceModule.meta_files_and_regexp?(module_branch)
        ret_with_removed_variants(meta_files).each do |meta_file|
          default_assembly_name = (if meta_file =~ regexp then $1; end)
          block.call(meta_file,default_assembly_name)
        end
      end

      def validate_service_instance_references(service_instances, module_branch)
        assembly_names = []
        assembly_names_with_templates = {}

        meta_files, regexp = ServiceModule.meta_files_and_regexp?(module_branch)
        assembly_file_paths = ret_with_removed_variants(meta_files)
        assembly_file_paths.each {|path| assembly_names << ServiceModule.meta_file_assembly_name(path)}

        service_instances.each do |instance|
          if parent = instance.copy_as_assembly_instance.get_parent
            parent_name = parent[:display_name]
            assembly_names_with_templates.merge!(instance[:display_name] => parent_name) unless assembly_names.include?(parent_name)
          end
        end

        unless assembly_names_with_templates.empty?
          instances = assembly_names_with_templates.keys
          templates = assembly_names_with_templates.values.uniq

          is = (instances.size == 1) ? 'is' : 'are'
          it = (templates.size == 1) ? 'it' : 'them'

          raise ErrorUsage.new("Cannot delete assembly template(s) '#{templates.join(', ')}' because service instance(s) '#{instances.join(', ')}' #{is} referencing #{it}.")
        end
      end

      def ret_with_removed_variants(paths)
        # if multiple files that match where one is json and one yaml, favor the default one
        two_variants_found = false
        common_paths = Hash.new
        paths.each do |path|
          if path  =~ /(^.+)\.([^\.]+$)/
            all_but_type,type = $1,$2
            if common_paths[all_but_type]
              two_variants_found = true
            else
              common_paths[all_but_type] = Array.new
            end
            common_paths[all_but_type] << {:type => type, :path => path}
          else
            Log.error("Path (#{path}) has unexpected form; skipping 'removing variants analysis'")
          end
        end
        # shortcut
        return paths unless two_variants_found
        format_type_default = R8::Config[:dsl][:service][:format_type][:default]
        ret = Array.new
        common_paths.each_value do |variant_info|
          if variant_info.size == 1
            ret << variant_info[:path]
          else
            if match = variant_info.find{|vi|vi[:type] == format_type_default}
              ret << match[:path]
            else
              choices = variant_info.amp{|vi|vi[:path]}.join(', ')
              raise ErrorUsage.new("Cannot decide between the following meta files to use (#{choices}); deleet all but desired one")
            end
          end
        end
        ret
      end

      def validate_name_for_assembly(file_path,name)
        return unless (name || file_path)
        assembly_name = ServiceModule.meta_file_assembly_name(file_path) || 'UNKNOWN'
        unless assembly_name.eql?(name)
          ParsingError::BadAssemblyReference.new(:file_path => file_path, :name => name) 
        end
      end

      def validate_module_ref_namespaces(module_branch,component_module_refs)
        cmp_modules = component_module_refs.component_modules
        namespace_mh = module_branch.id_handle().createMH(:namespace)

        sp_hash = {
          :cols => [:id, :display_name]
        }
        namespaces = Model.get_objs(namespace_mh,sp_hash).map{|ns| ns[:display_name]}

        cmp_modules.each do |k,v|
          v_namespace = v[:namespace_info]
          return ParsingError::BadNamespaceReference.new(:name => v_namespace) unless namespaces.include?(v_namespace)
        end
      end

      def parse_assembly_wide_components!(hash_content)
        return unless (hash_content['assembly'] && hash_content['assembly']['components'])

        assembly_wide_cmps = hash_content['assembly']['components']
        assembly_wide_cmps = assembly_wide_cmps.is_a?(Array) ? assembly_wide_cmps : [assembly_wide_cmps]

        if hash_content['assembly']['nodes']
          hash_content['assembly']['nodes'].merge!('assembly_wide' => {'components' => assembly_wide_cmps})
        else
          hash_content['assembly']['nodes'] = {'assembly_wide' => {'components' => assembly_wide_cmps}}
        end
      end

      # TODO: ref DTK-1619: if we put this back in we need to handle case where cmps has an element with a title like
      # cmp[title] or mod::cmp[title]; also would want to write or use a method in service/common that does not
      # hard code '::' put instead takes a component ref and returns a module name
#      def validate_component_names(hash_content,component_module_refs)
#        module_refs_cmps = component_module_refs.component_modules.map{|k,v| k.to_s}
#        nodes = hash_content['assembly']['nodes']||{}
#        nodes.each do |n_name,n_value|
#          cmps = n_value['components']
#          cmps.each do |c|
#            c_name = c.split('::').first
#            return ParsingError::BadComponentReference.new(:component_name => c, :node_name => n_name) unless module_refs_cmps.include?(c_name)
#          end
#        end

#        module_refs_cmps
#      end

      def meta_file_format_type(path)
        Aux.format_type(path)
      end

      def error_cleanup()
        # TODO: this is wrong;
        # ServiceModule.delete(id_handle())
        # determine if there is case where this is appropriate or have delete for other objects; can also case on dsl_parsed
        # TODO: may need to  write error cleanup for service module update that does not parse for service module (#{update_object!(:display_name,:dsl_parsed).inspect})")
      end
    end
  end
end


