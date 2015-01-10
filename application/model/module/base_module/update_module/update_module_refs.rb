module DTK; class BaseModule; class UpdateModule
  class UpdateModuleRefs
    def initialize(dsl_obj,base_module)
      @input_hash    = dsl_obj.input_hash
      @project_idh   = dsl_obj.project_idh
      @module_branch = dsl_obj.module_branch
      @base_module  = base_module
    end

    def self.update_component_module_refs(module_branch,matching_module_refs,base_module)
      # Get existing module_refs.yaml content to update module_ref dependencies
      syntatic_parsed_info = dsl_parser_class(base_module).parse_directory(module_branch,:component_module_refs)
      return syntatic_parsed_info if ModuleDSL::ParsingError.is_error?(syntatic_parsed_info)

      # Append new matching module_refs to existing ones that are already in module_refs.yaml
      if matching_module_refs && !matching_module_refs.empty?
        syntatic_parsed_info << matching_module_refs
        syntatic_parsed_info.flatten!
      end

      ModuleRefs::Parse.update_from_syntatic_parse(module_branch,syntatic_parsed_info)
    end

    def validate_includes_and_update_module_refs()
      ret = Hash.new
      
      # @input_hash is in normalized form
      includes = @input_hash.values.map{|v|(v['component_include_module']||{}).keys}.flatten(1)
      includes.uniq!
      unless includes.empty?
        mapped = ComponentModuleRef.get_matching(@project_idh,includes)
        multiple_namespaces = mapped.group_by { |h| h[:component_module] }.values.select { |a| a.size > 1 }.flatten
        
        mapped_names = mapped.map{|m| m[:component_module]}
        missing = includes - mapped_names
        ext_deps_hash = {
          :possibly_missing => missing
        }
        
        unless multiple_namespaces.empty?
          multi_missing, ambiguous_grouped, existing_names = [], {}, []
          multiple_namespaces.each{|mn| mapped.delete(mn)}
          
          check_if_matching_or_ambiguous(multiple_namespaces)
          # For Rich:
          # possible solution for problem that Bakir sent in his last email
          # uncomment these lines if caused any side effects
          # existing_module_refs = @module_branch.get_module_refs()
          # existing_module_refs.each do |existing_ref|
          #     existing_names << existing_ref[:display_name] if existing_ref[:namespace_info]
          # end
          
          # multiple_namespaces.delete_if{|mn| existing_names.include?(mn[:component_module])}
          cmp_mods = multiple_namespaces.group_by { |h| h[:component_module] }
          cmp_mods.each do |k,v|
            namespaces = v.map{|a| a[:remote_namespace]}
            ambiguous_grouped.merge!(k => namespaces)
          end
          unless ambiguous_grouped.empty?
            ret.merge!(:ambiguous => ambiguous_grouped)
            ext_deps_hash.merge!(:ambiguous => ambiguous_grouped)
          end
        end
        
        ret.merge!(:external_dependencies =>ExternalDependencies.new(ext_deps_hash))
        unless mapped.empty?
          self.class.update_component_module_refs(@module_branch,mapped,@base_module) 
          message = "The module refs file was updated by the server based on includes section from dtk.model.yaml"
          ret.merge!(:message => message)
        end
      end
      ret
    end
    
   private
    def self.dsl_parser_class(base_module)
      base_module.class::DSLParser
    end

    def check_if_matching_or_ambiguous(ambiguous)
      existing_c_hash = get_existing_module_refs()
      if existing = existing_c_hash['component_modules']
        existing.each do |k,v|
          if k && v
            amb = ambiguous.select{|a| a[:component_module].split('/').last.eql?(k) && a[:remote_namespace].eql?(v['namespace'])}
            ambiguous.delete_if{|amb| amb[:component_module].split('/').last.eql?(k)} unless amb.empty?
          end
        end
      end
    end
    
    def get_existing_module_refs()
      existing_c_hash  = {}
      existing_content = RepoManager.get_file_content({:path => "module_refs.yaml"}, @module_branch, {:no_error_if_not_found => true})
      existing_c_hash  = Aux.convert_to_hash(existing_content,:yaml) if existing_content
      existing_c_hash
    end
  end
end; end; end
