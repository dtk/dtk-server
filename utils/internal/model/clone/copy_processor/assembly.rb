module DTK
  class Clone
    class CopyProcessor
      class Assembly < self
        def cloning_assembly?()
          true
        end
        def clone_direction()
          :library_to_target
        end
        
        attr_reader :project
        def service_add_on_node_bindings()
          @service_add_on_proc.node_bindings()
        end
        def get_service_add_on_mapped_nodes(create_override_attrs,create_opts)
          @service_add_on_proc.get_mapped_nodes(create_override_attrs,create_opts)
        end

       private
        def initialize(target_obj,source_obj,opts={})
          super(source_obj,opts)
          @project = (target_obj.respond_to?(:get_project) && target_obj.get_project)
          @service_add_on_proc = ServiceAddOnProc.new(opts[:service_add_on_info])
        end

        def get_nested_objects_top_level(model_handle,target_parent_mh,assembly_objs_info,recursive_override_attrs,opts={},&block)
          ret = Array.new
          raise Error.new("Not treating assembly_objs_info with more than 1 element") unless assembly_objs_info.size == 1
          assembly_obj_info = assembly_objs_info.first
          ancestor_id = assembly_obj_info[:ancestor_id]
          target_parent_mn = target_parent_mh[:model_name]
          model_name = model_handle[:model_name]
          new_assembly_assign = {:assembly_id => assembly_obj_info[:id]}
          new_par_assign = {DB.parent_field(target_parent_mn,model_name) => assembly_obj_info[:parent_id]}
          Global::AssemblyChildren.each do |nested_model_name|
            #TODO: push this into ChildContext.create_from_hash
            nested_mh = model_handle.createMH(:model_name => nested_model_name, :parent_model_name => target_parent_mn)
            override_attrs = new_assembly_assign.merge(ret_child_override_attrs(nested_mh,recursive_override_attrs))
            create_opts = {:duplicate_refs => :allow, :returning_sql_cols => [:ancestor_id,:assembly_id]}

            #putting in nulls to null-out; more efficient to omit this columns in create
            parent_rel = (DB_REL_DEF[nested_model_name][:many_to_one]||[]).inject({:old_par_id => ancestor_id}) do |hash,pos_par|
              hash.merge(Model.matching_models?(pos_par,target_parent_mn) ? new_par_assign : {DB.parent_field(pos_par,model_name) => SQL::ColRef.null_id})
            end
            if Model.matching_models?(nested_model_name,:node) 
              unless (override_attrs[:component]||{})[:assembly_id]
                override_attrs.merge!(:component => new_assembly_assign)
              end
            end
            target_idh = target_parent_mh.createIDH(:id => assembly_obj_info[:parent_id])
            child_context = ChildContext.create_from_hash(self,{:model_handle => nested_mh, :clone_par_col => :assembly_id, :parent_rels => [parent_rel], :override_attrs => override_attrs, :create_opts => create_opts, :ancestor_id => ancestor_id, :target_idh => target_idh})
            if block
              block.call(child_context)
            else
              ret << child_context
            end
          end
          ret unless block
        end
        class ServiceAddOnProc
          def initialize(service_add_on_info)
            if service_add_on_info
              @node_bindings = service_add_on_info[:service_add_on].get_service_node_bindings()
              @port_links = service_add_on_info[:service_add_on].get_port_links()
              @base_assembly = service_add_on_info[:base_assembly]
            else
              @node_bindings = Array.new
              @port_links = Array.new
              @base_assembly = nil
            end
          end
          attr_reader :node_bindings

          def get_mapped_nodes(create_override_attrs,create_opts)
            ret = Array.new
            return ret unless @base_assembly and @node_bindings and not @node_bindings.empty? 
            cols_needed = (create_opts[:returning_sql_cols]||[]) - create_override_attrs.keys
            unless missing = (cols_needed - [:ancestor_id]).empty?
              raise Error.new("Not implemented: get_mapped_nodes returning cols (#{missing.join(",")})")
            end
            sp_hash = {
              :cols => [:id,:group_id,:ancestor_id],
              :filter => [:and, [:eq,:assembly_id,@base_assembly[:id]],
                          [:oneof,:ancestor_id,@node_bindings.map{|nb|nb[:assembly_node_id]}]]
              
            }
            node_mh = @base_assembly.model_handle(:node)
            ret = Model.get_objs(node_mh,sp_hash)
            ndx_node_bindings = @node_bindings.inject(Hash.new){|h,nb|h.merge(nb[:assembly_node_id] => nb)}
            ret.each do |a|
              mapped_ancestor_id = ndx_node_bindings[a[:ancestor_id]][:sub_assembly_node_id]
              a[:ancestor_id] = mapped_ancestor_id
              a[:node_template_id] = mapped_ancestor_id
            end
            ret
          end
        end
      end
    end
  end
end
