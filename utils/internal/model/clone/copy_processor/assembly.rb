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
       private
        def initialize(target_obj,source_obj,opts={})
          super(source_obj,opts)
          @project = (target_obj.respond_to?(:get_project) && target_obj.get_project)
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
      end
    end
  end
end
