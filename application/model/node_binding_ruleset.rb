module XYZ
  class NodeBindingRuleset < Model
    def self.common_columns()
      [:id,:display_name,:type,:os_type,:rules]
    end
    
    def clone_or_match(target)
      update_object!(:type,:rules)
      case self[:type]
       when "clone"
        clone(target)
       when "match"
        match(target)
      else
        raise Error.new("Unexpected type (#{self[:type]}) in node bidning ruleset")
      end
    end
   private
    def match(target)
      raise Error.new("TODO: not implemented yet")
    end
    
    def clone(target)
      #match conditions in ruleset with properties on target
      target.update_object!(:iaas_type,:iaas_properties)
      match = clone_match(target)
      raise Error.new("No rules in the node being match the target") unless match

      node_template = get_node_template(match[:node_template])
      raise Error.new("Cannot find associated node template") unless node_template

      override_attrs = Hash.new 
      clone_opts = node_template.source_clone_info_opts()
      new_obj = target.clone_into(node_template,override_attrs,clone_opts)
      new_obj && new_obj.id_handle()
    end

    def clone_match(target)
      CommandAndControl.clone_match(self[:rules],target)
    end

    def get_node_template(node_template_ref)
      sp_hash = {
        :cols => [:id, :display_name, :group_id],
        :filter => [:eq,:node_binding_rs_id,id()]
      }
      Model.get_objs(id_handle.createMH(:node),sp_hash).first
    end
  end
end

