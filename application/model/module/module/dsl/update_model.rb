module DTK; class ModuleDSL
  module UpdateModelMixin
    def update_model(opts={})
      input_hash =
        if opts.empty?
          @input_hash
        elsif opts[:version]
          modify_for_version_and_override_attrs(@input_hash,opts[:version],opts[:override_attrs])
        else
          add_component_override_attrs(@input_hash,opts[:override_attrs])
        end

      self.class.add_components_from_dsl(@project_idh,@config_agent_type,@impl_idh,input_hash,nil,opts)
    end

    class Parser
      def initialize(impl_idh,module_branch_idh,project_idh)
        @impl_idh = impl_idh
        @module_branch_idh = module_branch_idh
        @project_idh = project_idh
        @remote_link_defs = {}
        @components_hash = {}
        @stored_components_hash = {}
      end
      attr_reader :components_hash,:stored_components_hash

      def parse_components!(config_agent_type,dsl_hash,namespace)
        impl_id = impl_idh.get_id()
        module_branch_id = module_branch_idh.get_id()

        @components_hash = dsl_hash.inject({}) do |h, (r8_hash_cmp_ref,cmp_info)|
          cmp_ref = component_ref(config_agent_type,r8_hash_cmp_ref,namespace)
          info = {}
          cmp_info.each do |k,v|
            case k
            # TODO: deprecate this case when remove v1
            when "external_link_defs"
              v.each{|ld|(ld["possible_links"]||[]).each{|pl|pl.values.first["type"] = "external"}} #TODO: temp hack to put in type = "external"
              parsed_link_def = LinkDef.parse_serialized_form_local(v,config_agent_type,@remote_link_defs,cmp_ref)
              (info["link_def"] ||= {}).merge!(parsed_link_def)
            when "link_defs"
              parsed_link_def = LinkDef.parse_serialized_form_local(v,config_agent_type,@remote_link_defs,cmp_ref)
              (info["link_def"] ||= {}).merge!(parsed_link_def)
            else
              info[k] = v
            end
          end
          info.merge!("implementation_id" => impl_id, "module_branch_id" => module_branch_id)
          h.merge(cmp_ref => info)
        end
      end

      private

      attr_reader :impl_idh, :module_branch_idh,:project_idh

      def component_ref_from_cmp_type(config_agent_type,component_type)
        "#{config_agent_type}-#{component_type}"
      end

      def component_ref(config_agent_type,hash_cmp_ref,namespace)
        ref_wo_ns = "#{config_agent_type}-#{hash_cmp_ref}"
        Namespace.join_namespace(namespace, ref_wo_ns)
      end
    end

    private

    def add_component_override_attrs(input_hash,override_attrs)
      if override_attrs
        input_hash.keys.inject({}) do |h,k|
          h.merge(k => input_hash[k].merge(override_attrs))
        end
      else
        input_hash
      end
    end

    def modify_for_version_and_override_attrs(input_hash,version,override_attrs)
      (override_attrs ||= {})["version"] ||= version

      input_hash.keys.inject({}) do |h,k|
        cmp_info = input_hash[k]
        modified_cmp_info = cmp_info.merge(override_attrs).merge("display_name" => Component.name_with_version(cmp_info["display_name"],version))
        h.merge(Component.ref_with_version(k,version) => modified_cmp_info)
      end
    end
  end

  module UpdateModelClassMixin
    def add_components_from_dsl(project_idh,config_agent_type,impl_idh,dsl_hash,dsl_integer_version=nil,opts={})
      dsl_integer_version ||= integer_version(dsl_integer_version)
      module_branch_idh = impl_idh.create_object().get_module_branch().id_handle()
      parser_proc = create_parser_processor(dsl_integer_version,impl_idh,module_branch_idh,project_idh)
      parser_proc.parse_components!(config_agent_type,dsl_hash,opts[:namespace])
      cmps_hash = parser_proc.components_hash()
      stored_cmps_hash = parser_proc.stored_components_hash()

      # data_source_update_hash form used so can annotate subcomponents with "is complete" so will delete items that are removed
      db_update_hash = db_update_form(cmps_hash,stored_cmps_hash,module_branch_idh)
      Model.input_hash_content_into_model(project_idh,db_update_hash)
      sp_hash =  {
        cols: [:id,:display_name],
        filter: [:and,[:oneof,:ref,cmps_hash.keys],[:eq,:project_project_id,project_idh.get_id()]]
      }
      Model.get_objs(project_idh.create_childMH(:component),sp_hash).map(&:id_handle)
    end

    private

    def create_parser_processor(dsl_integer_version,impl_idh,module_branch_idh,project_idh)
      klass = load_and_return_version_adapter_class(dsl_integer_version)
      klass.const_get("Parser").new(impl_idh,module_branch_idh,project_idh)
    end

    # This marks as complete applicable objects so if objects not present in cmps_input_hash they are deleted
    def db_update_form(cmps_input_hash,non_complete_cmps_input_hash,module_branch_idh)
      mark_as_complete_constraint = {
        module_branch_id: module_branch_idh.get_id(), #so only delete extra components that belong to same module
        node_node_id: nil #so only delete component templates and not component instances
      }
      cmp_db_update_hash = cmps_input_hash.inject(DBUpdateHash.new) do |h,(ref,hash_assigns)|
        h.merge(ref => db_update_form_aux(:component,hash_assigns))
      end.mark_as_complete(mark_as_complete_constraint)
      {"component" => cmp_db_update_hash.merge(non_complete_cmps_input_hash)}
    end

    def db_update_form_aux(model_name,hash_assigns)
      ret = DBUpdateHash.new
      children_model_names = DB_REL_DEF[model_name][:one_to_many]||[]
      hash_assigns.each do |key,child_hash|
        key = key.to_sym
        if children_model_names.include?(key)
          child_model_name = key
          ret[key] = child_hash.inject(DBUpdateHash.new) do |h,(ref,child_hash_assigns)|
            h.merge(ref => db_update_form_aux(child_model_name,child_hash_assigns))
          end
          ret[key].mark_as_complete()
        else
          ret[key] = child_hash
        end
      end
      # mark as complete any child that does not appear in hash_assigns
      (children_model_names - hash_assigns.keys.map(&:to_sym)).each do |key|
        ret[key] = DBUpdateHash.new().mark_as_complete()
      end
      ret
    end
  end
end; end
