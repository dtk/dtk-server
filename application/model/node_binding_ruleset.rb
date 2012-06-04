module XYZ
  class NodeBindingRuleset < Model
    def self.common_columns()
      [:id,:display_name,:type,:os_type,:rules]
    end

    def find_matching_node_template(target)
      match = CommandAndControl.find_matching_node_binding_rule(self[:rules],target)
      raise Error.new("No rules in the node being match the target") unless match
      get_node_template(match[:node_template])
    end
    
    def clone_or_match(target)
      update_object!(:type,:rules)
      case self[:type]
       when "clone"
        clone(target)
       when "match"
        match(target)
      else
        raise Error.new("Unexpected type (#{self[:type]}) in node binding ruleset")
      end
    end
   private
    def match(target)
      raise Error.new("TODO: not implemented yet")
    end
    
    def clone(target)
      node_template = find_matching_node_template(target)
      override_attrs = Hash.new 
      clone_opts = node_template.source_clone_info_opts()
      new_obj = target.clone_into(node_template,override_attrs,clone_opts)
      new_obj && new_obj.id_handle()
    end

    def get_node_template(node_template_ref)
      sp_hash = {
        :cols => [:id, :display_name, :group_id],
        :filter => [:and, [:eq,:node_binding_rs_id,id()], [:eq,:type,"image"]]
      }
      ret = Model.get_obj(id_handle.createMH(:node),sp_hash)
      raise Error.new("Cannot find associated node template") unless ret
      ret
    end
  end
end

