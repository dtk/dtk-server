# TODO: this needs much cleanup: may spearete into parts fro assemblies and then teh rest which is containment based copying
# TODO: try to move more to chidl context geenraizing to be object context and possibly using it to subsume cloneprocesseor
r8_nested_require('clone','child_context') #TODO: move to inside class
module DTK
  class Clone
    r8_nested_require('clone','copy_processor') #TODO: better to not need copy_processor and just make part of this class
    r8_nested_require('clone','global')
  end
  module CloneClassMixins
    # TODO: may just be temporary; this function takes into account that front end may not send teh actual target handle for componenst who parents
    # are on components not nodes
    def find_real_target_id_handle(id_handle,specified_target_idh)
      return specified_target_idh unless id_handle[:model_name] == :component and specified_target_idh[:model_name] == :node
      id_handle.create_object().determine_cloned_components_parent(specified_target_idh)
    end
  end

  module CloneInstanceMixins
    def clone_into(clone_source_object,override_attrs={},opts={})
      unless opts[:ret_new_obj_with_cols]
        Log.error("TODO: may be error when :ret_new_obj_with_cols omitted in Model#clone_into")
      end
      target_id_handle = id_handle_with_auth_info()
      clone_source_object = clone_pre_copy_hook(clone_source_object,opts)
      clone_source_object.add_model_specific_override_attrs!(override_attrs,self)
      proc = Clone::CopyProcessor.create(self,clone_source_object,opts.merge(:include_children => true))
      clone_copy_output = proc.clone_copy_top_level(clone_source_object.id_handle,[target_id_handle],override_attrs)
      new_id_handle = clone_copy_output.id_handles.first
      return nil unless new_id_handle

      # calling with respect to target
      if service_add_on_proc = proc.service_add_on_proc?()
        opts.merge!(:service_add_on_proc => service_add_on_proc)
      end
      clone_post_copy_hook(clone_copy_output,opts)

      if clone_source_object.class == Component and target_id_handle[:model_name] == :node
        Violation.update_violations([target_id_handle])
      end
      if opts[:ret_new_obj_with_cols]
        clone_copy_output.objects.first
      else
        new_id_handle.get_id()
      end
    end

    # TODO: bleow wil be deprecated
    def clone_into_library_assembly(assembly_idh,id_handles)
      opts = {:include_children => true}
      proc = Clone::CopyProcessor.create(self,assembly_idh.create_object(),opts)
      proc.add_id_handle(assembly_idh)

      # group id handles by model type
      ndx_id_handle_groups = Hash.new
      id_handles.each do |idh|
        model_name = idh[:model_name]
        (ndx_id_handle_groups[model_name] ||= Array.new) << idh
      end

      assembly_id_assign = {:assembly_id => assembly_idh.get_id()}
      overrides = assembly_id_assign.merge(:type => "stub",:component => assembly_id_assign)
      ndx_id_handle_groups.each_value do |child_id_handles|
        child_context = proc.child_context_lib_assembly_top_level(child_id_handles,id_handle(),overrides)
        proc.clone_copy_child_objects(child_context)
      end

      proc.shift_foregn_keys()
      # TODO: check if clone_post copy needs to be done after key shift; if not can simplify
      clone_copy_output = proc.output
      clone_post_copy_hook(clone_copy_output)

      assembly_idh.get_id()
    end

    def get_constraints()
      get_constraints!()
    end

    # this gets optionally overwritten
    def source_clone_info_opts()
      {:ret_new_obj_with_cols => [:id]}
    end

   protected
    # to be optionally overwritten by object representing the source
    def add_model_specific_override_attrs!(override_attrs,target_obj)
    end

    # to be optionally overwritten by object representing the target
    def clone_pre_copy_hook(clone_source_object,opts={})
      clone_source_object
    end 

    # to be optionally overwritten by object representing the target
    def clone_post_copy_hook(clone_copy_output,opts={})
    end
      
    # to be overwritten
    # opts can be {:update_object => true} to update object
    def get_constraints!(opts={})
      nil
    end
  end
end
