# TODO: this needs much cleanup: may spearete into parts fro assemblies and then teh rest which is containment based copying
# TODO: try to move more to chidl context geenraizing to be object context and possibly using it to subsume cloneprocesseor
module DTK
  class Clone
    module InstanceTemplate
      r8_nested_require('clone','instance_template/link')
      r8_nested_require('clone','instance_template/links')
    end

    r8_nested_require('clone','child_context') 
    #TODO: better to not need copy_processor and just make part of this class
    r8_nested_require('clone','copy_processor') 
    r8_nested_require('clone','global')
    r8_nested_require('clone','incremental_update')

    #instance_template_links has type InstanceTemplate::Links
    def self.modify_instances(instance_template_links)
      ChildContext.modify_instances(instance_template_links)
    end

    # parent_links of type InstanceTemplate::Links
    def self.create_child_objects(template_child_idhs,parent_links)
      ret = Array.new
      return ret if template_child_idhs.empty? or parent_links.empty?
      child_context = ChildContext.create_from_parent_links(template_child_idhs,parent_links)
      child_context.create_new_objects()
    end
    # parent_link of type InstanceTemplate::Link
    def self.create_child_object(template_child_idhs,parent_link)
      parent_links = InstanceTemplate::Links.new
      parent_links.add(parent_link.instance,parent_link.template)
      create_child_objects(template_child_idhs,parent_links).first
    end

    module Mixins
      def clone_into(clone_source_object,override_attrs={},opts={})
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
# TODO: for debugging
stop = R8::Config[:stop_for_testing]
if stop then raise ErrorUsage.new('stop for testing'); end
        
        if clone_source_object.class == Component and target_id_handle[:model_name] == :node
          Violation.update_violations([target_id_handle])
        end
        if opts[:ret_new_obj_with_cols]
          clone_copy_output.objects.first
        else
          new_id_handle.get_id()
        end
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

    module ClassMixins
      # TODO: may just be temporary; this function takes into account that front end may not send teh actual target handle for componenst who parents
      # are on components not nodes
      def find_real_target_id_handle(id_handle,specified_target_idh)
        return specified_target_idh unless id_handle[:model_name] == :component and specified_target_idh[:model_name] == :node
        id_handle.create_object().determine_cloned_components_parent(specified_target_idh)
      end
    end

  end
end
