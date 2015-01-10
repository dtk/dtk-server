module DTK
  class ModuleRefs
    module MatchingTemplatesMixin
      # component refs are augmented with :component_template key which points to 
      # associated component template or nil 
      # This method can be called when assembly is imported or staged
      # TODO: any other time this can be called
      def set_matching_component_template_info?(aug_cmp_refs,opts={})
        ret = aug_cmp_refs
        if aug_cmp_refs.empty?
          return ret 
        end
        # determine which elements of aug_cmp_refs need to be matches
        cmp_types_to_check = determine_component_refs_needing_matches(aug_cmp_refs,opts)
        if cmp_types_to_check.empty?
          return ret 
        end
        set_matching_component_template_info!(aug_cmp_refs,cmp_types_to_check,opts)
        ret
      end

     private
      def determine_component_refs_needing_matches(aug_cmp_refs,opts={})
        # for each element in aug_cmp_ref, want to set cmp_template_id using following rules
        # 1) if key 'has_override_version' is set
        #    a) if it points to a component template, use this
        #    b) otherwise look it up using given version
        # 2) else look it up and if lookup exists use this as the value to use; element marked required if it does not point to a component template
        # lookup based on matching both version and namespace, if namespace is given
        cmp_types_to_check = Hash.new
        aug_cmp_refs.each do |r|
          unless cmp_type = r[:component_type]||(r[:component_template]||{})[:component_type]
            ref =  ComponentRef.print_form(r)
            ref = (ref ? "(#{ref})" : "")
            raise Error.new("Component ref #{ref} must either point to a component template or have component_type set")
          end
          cmp_template_id = r[:component_template_id]
          if r[:has_override_version]
            unless cmp_template_id
              unless r[:version]
                raise Error.new("Component ref has override-version flag set, but no version")
              end
              (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << {:pntr => r, :version => r[:version]}
            end
          else
            add_item = true
            if r[:template_id_synched] and not opts[:force_compute_template_id]
              if cmp_template_id.nil?
                Log.error("Unexpected that cmp_template_id is null for (#{r.inspect})")
              else
                add_item = false
              end
            end
            if add_item
              (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << {:pntr => r,:required => cmp_template_id.nil?}
            end
          end
          r[:template_id_synched] = true #marking each item synchronized
        end

        # shortcut if no locked versions and no required elements
        if component_modules().empty? and not cmp_types_to_check.values.find{|r|r.mapping_required?()}
          # TODO: should we instead prune out all those that dont have mapping required
          return Hash.new
        end
        cmp_types_to_check
      end

      def set_matching_component_template_info!(aug_cmp_refs,cmp_types_to_check,opts={})
        ret = aug_cmp_refs
        # Lookup up modules mapping
        # mappings will have key for each component type referenced and for each key will return hash with keys :component_template and :version;
        # component_template will be null if no match is found
        mappings = get_component_type_to_template_mappings?(cmp_types_to_check.keys)

        # set the component template ids; raise error if there is a required element that does not have a matching component template

        if opts[:set_namespace]
          ret.each do |cmp_ref|
            cmp_type = cmp_ref[:component_type]
            next unless cmp_types_to_check[cmp_type]
            if cmp_type_info = mappings[cmp_type]
              if namespace = cmp_type_info[:namespace]
                cmp_ref[:namespace] = namespace
              end
            end
          end
        end

        reference_errors = Array.new
        cmp_types_to_check.each do |cmp_type,els|
          els.each do |el|
            cmp_type_info = mappings[cmp_type]
            if cmp_template = cmp_type_info[:component_template]
              el[:pntr][:component_template_id] = cmp_template[:id] 
              unless opts[:donot_set_component_templates]
                el[:pntr][:component_template] = cmp_template
              end
            elsif el[:required]
              # TODO: This should not be reached because if error then an error wil be raised by get_component_type_to_template_mappings? call
             Log.error("TODO: may put back in logic to accrue errors; until then this should not be reached")
#              cmp_ref = {
#                :component_type => cmp_type, 
#                :version => cmp_type_info[:version]
#              }
#              reference_errors << cmp_ref
            end
          end
        end
        unless reference_errors.empty?
          raise ServiceModule::ParsingError::DanglingComponentRefs.new(reference_errors) 
        end
        update_module_refs_dsl?(mappings)
        ret
      end

      def get_component_type_to_template_mappings?(cmp_types,opts={})
        ret = Hash.new
        return ret if cmp_types.empty?
        # first put in ret info about component type and version
        ret = cmp_types.inject(Hash.new) do |h,cmp_type|
          version = version_string?(cmp_type)
          el = Component::Template::MatchElement.new(
            :component_type => cmp_type, 
            :version_field => ModuleBranch.version_field(version)
          )
          if version
            el[:version] = version
          end
          if namespace = namespace?(cmp_type)
            el[:namespace] = namespace
          end
          h.merge(cmp_type => el)
        end

        # get matching component template info and insert matches into ret
        Component::Template.get_matching_elements(project_idh(),ret.values,opts).each do |cmp_template|
          ret[cmp_template[:component_type]].merge!(:component_template => cmp_template) 
        end
        ret
      end

      def update_module_refs_dsl?(cmp_type_to_template_mappings)
        module_name_to_ns = Hash.new
        cmp_type_to_template_mappings.each do |cmp_type,cmp_info|
          module_name = module_name(cmp_type)
          unless module_name_to_ns[module_name] 
            if namespace = (cmp_info[:component_template]||{})[:namespace]
              module_name_to_ns[module_name] = namespace
            end
          end
        end
        cmp_module_refs_to_add = Array.new
        module_name_to_ns.each do |cmp_module_name,namespace|
          if component_module_ref = component_module_ref?(cmp_module_name)
            unless component_module_ref.namespace() == namespace
              raise Error.new("Unexpected that at this point component_module_ref.namespace() (#{component_module_ref.namespace()}) unequal to namespace (#{namespace})")
            end
          else
            new_cmp_moule_ref = {
              :module_name=>cmp_module_name,
              :module_type=>"component",
              :namespace_info=>namespace
            }
            cmp_module_refs_to_add <<  new_cmp_moule_ref
          end
        end
        unless cmp_module_refs_to_add.empty?
          ModuleRef.update(:add,@parent,cmp_module_refs_to_add)
        end
      end

      def version_string?(component_type)
        if cmp_module_ref = component_types_module_ref?(component_type)
          cmp_module_ref.version_string()
        end
      end

      def namespace?(component_type)
        if cmp_module_ref = component_types_module_ref?(component_type)
          cmp_module_ref.namespace()
        end
      end
      
      def module_name(component_type)
        Component.module_name(component_type)
      end

      def component_types_module_ref?(component_type)
        component_module_ref?(module_name(component_type))
      end
    end
  end
end

