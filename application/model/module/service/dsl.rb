module DTK
  class ServiceModule
    r8_nested_require('dsl','common')
    r8_nested_require('dsl','assembly_import')
    r8_nested_require('dsl','assembly_export')
    r8_nested_require('dsl','parser')
    r8_nested_require('dsl','parsing_error')

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
      def delete_assembly_dsl?(assembly_idh)
        sp_hash = {
          :cols => [:display_name, :module_branch],
          :filter => [:eq,:id,assembly_idh.get_id()]
        }
        assembly_mh = assembly_idh.createMH()
        ndx_module_branches = Hash.new
        get_objs(assembly_mh,sp_hash).each do |r|
          module_branch = r[:module_branch]
          assembly_name = r[:display_name]
          assembly_dir = assembly_meta_directory_path(assembly_name)
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

      def assembly_meta_directory_path(assembly_name)
        "assemblies/#{assembly_name}"
      end
      def assembly_meta_filename_path(assembly_name)
        file_type = dsl_files_format_type()
        "#{assembly_meta_directory_path(assembly_name)}/assembly.#{file_type}"
      end

      def assembly_workflow_meta_filename_path(assembly_name,task_action)
        file_type = dsl_files_format_type()
        "#{assembly_meta_directory_path(assembly_name)}/workflows/#{task_action}.#{file_type}"
      end

      def dsl_files_format_type()
        format_type_default = R8::Config[:dsl][:service][:format_type][:default]
        case format_type_default
        when "json" then "json"
        when "yaml" then "yaml"
          else raise Error.new("Unexepcted value for dsl.service.format_type.default: #{format_type_default}")
        end
      end
      private :dsl_files_format_type
    end

    module DSLMixin
      def update_model_from_dsl(module_branch,opts={})
        set_dsl_parsed!(false)
        component_module_refs = update_component_module_refs(module_branch,opts)
        return component_module_refs if ParsingError.is_error?(component_module_refs)

        parsed = update_assemblies_from_dsl(module_branch,component_module_refs,opts)
        set_dsl_parsed!(true) unless ParsingError.is_error?(parsed)
        parsed
      end

     private
      def update_component_module_refs(module_branch,opts={})
        parsed_info = 
          if DSLParser.implements_method?(:parse_directory)
            DSLParser.parse_directory(module_branch,:component_module_refs,opts)
          else
            DSLParser::Output.new(:component_module_refs,legacy_component_module_refs_parsed_info(module_branch,opts))
          end
        return parsed_info if ParsingError.is_error?(parsed_info)
        ComponentModuleRefs.update_from_dsl_parsed_info(module_branch,parsed_info,opts)
      end

      # TODO: deprecate when DSLParser methods stable
      def legacy_component_module_refs_parsed_info(module_branch,opts={})
        ret = Hash.new
        meta_filename_path = ComponentModuleRefs.meta_filename_path()
        if json_content = RepoManager.get_file_content(meta_filename_path,module_branch,:no_error_if_not_found=>true)
          ret = Aux.json_parse(json_content,meta_filename_path)
        end
        ret
      end

      def update_assemblies_from_dsl(module_branch,component_module_refs,opts={})
        project_idh = get_project.id_handle()
        module_name = module_name()
        module_branch_idh = module_branch.id_handle()

        setting_files = check_if_settings_exist(module_branch)
        new_structure = setting_files.empty? ? false : true

        assembly_import_helper = AssemblyImport.new(project_idh,module_branch,module_name,component_module_refs)
        #TODO: make more general than just aggregating DanglingComponentRefs
        dangling_errors = ParsingError::DanglingComponentRefs::Aggregate.new(:error_cleanup => proc{error_cleanup()})
        assembly_meta_file_paths(module_branch, new_structure) do |meta_file,default_assembly_name|
          dangling_errors.aggregate_errors!()  do
            file_content = RepoManager.get_file_content(meta_file,module_branch)
            format_type = meta_file_format_type(meta_file)
            opts.merge!(:file_path => meta_file,:default_assembly_name => default_assembly_name)
            
            hash_content = Aux.convert_to_hash(file_content,format_type,opts)||{}
            return hash_content if ParsingError.is_error?(hash_content)
            imported = assembly_import_helper.process(module_name,hash_content,opts)
            return imported if ParsingError.is_error?(imported)
          end
        end
        errors = dangling_errors.raise_error?(:do_not_raise => true)
        return errors if errors.is_a?(ParsingError::DanglingComponentRefs)

        imported = assembly_import_helper.import()
        create_setting_objects_from_dsl(module_branch, component_module_refs, imported, opts)

        imported
      end

      def create_setting_objects_from_dsl(module_branch, component_module_refs, imported, opts={})
        project_idh        = get_project.id_handle()
        module_name        = module_name()
        module_branch_idh  = module_branch.id_handle()
        hash_content, hash = {}, {}
        display_name, type = nil, nil

        imported.each do |k,v|
          display_name = v["display_name"]
          type = v["type"]
        end

        sp_hash = {
          :cols => [:id],
          :filter => [:and, [:eq, :display_name, display_name], [:eq, :type, type]]
        }
        cmp_mh = project_idh.createMH(:component)
        cmp = Model.get_obj(cmp_mh,sp_hash)
        cmp_idh = cmp_mh.createIDH(:id => cmp[:id])

        dangling_errors = ParsingError::DanglingComponentRefs::Aggregate.new(:error_cleanup => proc{error_cleanup()})
        setting_meta_file_paths(module_branch) do |meta_file,default_assembly_name|
          dangling_errors.aggregate_errors!()  do
            file_content = RepoManager.get_file_content(meta_file,module_branch)
            format_type = meta_file_format_type(meta_file)
            opts.merge!(:file_path => meta_file,:default_assembly_name => default_assembly_name)

            hash_content = Aux.convert_to_hash(file_content,format_type,opts)||{}
            return hash_content if ParsingError.is_error?(hash_content)

            hash.merge!(add_settings_into_hash(hash_content, cmp))
            Model.input_hash_content_into_model(cmp_idh, hash)
          end
        end

        errors = dangling_errors.raise_error?(:do_not_raise => true)
        return errors if errors.is_a?(ParsingError::DanglingComponentRefs)
      end

      def add_settings_into_hash(hash_content, cmp)
        ref = hash_content['name']
        {
          "service_setting" => {
            ref => {
              :display_name => hash_content['name'],
              :node_bindings => hash_content['node_bindings'],
              :attribute_settings => hash_content['attribute_settings'],
              :component_component_id => cmp[:id]
            }
          }
        }
      end

      def check_if_settings_exist(module_branch)
        ret = {}
        setting_dsl_path_info = SettingFilenamePathInfo
        depth = setting_dsl_path_info[:path_depth]
        ret = RepoManager.ls_r(depth,{:file_only => true},module_branch)
        regexp = setting_dsl_path_info[:regexp]
        ret.reject!{|f|not (f =~ regexp)}
        ret
      end

      def setting_meta_file_paths(module_branch,&block)
        setting_dsl_path_info = SettingFilenamePathInfo
        depth = setting_dsl_path_info[:path_depth]
        ret = RepoManager.ls_r(depth,{:file_only => true},module_branch)
        regexp = setting_dsl_path_info[:regexp]
        ret.reject!{|f|not (f =~ regexp)}
        ret_with_removed_variants(ret).each do |meta_file|
          default_assembly_name = (if meta_file =~ regexp then $1; end)
          block.call(meta_file,default_assembly_name)
        end
      end
      SettingFilenamePathInfo = {
        :regexp => Regexp.new("^assemblies/([^/]+)/(.*)\.settings\.(.*)\.(json|yaml)$"),
        :path_depth => 4
      }

      # signature is  assembly_meta_file_paths(module_branch) do |meta_file,default_assembly_name|
      def assembly_meta_file_paths(module_branch, new_structure, &block)
        assembly_dsl_path_info = new_structure ? AssemblyFilenamePathInfoNew : AssemblyFilenamePathInfo
        depth = assembly_dsl_path_info[:path_depth]
        ret = RepoManager.ls_r(depth,{:file_only => true},module_branch)
        regexp = assembly_dsl_path_info[:regexp]
        ret.reject!{|f|not (f =~ regexp)}
        ret_with_removed_variants(ret).each do |meta_file|
          default_assembly_name = (if meta_file =~ regexp then $1; end) 
          block.call(meta_file,default_assembly_name)
        end
      end
      AssemblyFilenamePathInfo = {
        :regexp => Regexp.new("^assemblies/([^/]+)/assembly\.(json|yaml)$"),
        :path_depth => 3
      }
      AssemblyFilenamePathInfoNew = {
        :regexp => Regexp.new("^assemblies/(.*)\.assembly\.(.*)\.(json|yaml)$"),
        :path_depth => 3
      }

      def ret_with_removed_variants(paths)
        # if multiple files that match where one is json and one yaml, fafavor the default one
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


