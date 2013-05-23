module XYZ
  class NodeBindingRuleset < Model
    def self.common_columns()
      [:id,:display_name,:type,:os_type,:rules, :ref]
    end

    def self.check_valid_id(model_handle,id)
      check_valid_id_default(model_handle,id)
    end
    
    def self.name_to_id(model_handle, name)
      return name.to_i if name.match(/^[0-9]+$/)
      sp_hash =  {
        :cols => [:id],
        :filter => [:eq, :ref, name]
      }
      name_to_id_helper(model_handle,name,sp_hash)
    end

    def find_matching_node_template(target)
      match = CommandAndControl.find_matching_node_binding_rule(self[:rules],target)
      raise Error.new("No rules in the node being match the target") unless match
      get_node_template(match[:node_template])
    end
    
    def clone_or_match(target,opts={})
      update_object!(:type,:rules)
      case self[:type]
       when "clone"
        clone(target,opts)
       when "match"
        match(target,opts)
      else
        raise Error.new("Unexpected type (#{self[:type]}) in node binding ruleset")
      end
    end

    def ret_common_fields_or_that_varies()
      ret = Hash.new
      return ret unless self[:rules]
      first_time = true
      self[:rules].each do |rule|
        nt = rule[:node_template]
        RuleSetFields.each do |k|
          if ret[k] == :varies
            #no op
          elsif ret[k]
            ret[k] = :varies if ret[k] != nt[k]
          elsif first_time
            ret[k] = nt[k]
          else
            ret[k] = :varies
          end
        end
        first_time = false
      end
      ret
    end
    RuleSetFields = [:type,:image_id,:region,:size]

   private
    def match(target,opts={})
      raise Error.new("TODO: not implemented yet")
    end
    
    def clone(target,opts={})
      node_template = find_matching_node_template(target)
      override_attrs = opts[:override_attrs]||Hash.new 
      clone_opts = node_template.source_clone_info_opts()
      new_obj = target.clone_into(node_template,override_attrs,clone_opts)
      new_obj && new_obj.id_handle()
    end

    def get_node_template(node_template_ref)
      sp_hash = {
        :cols => [:id, :display_name, :external_ref, :group_id],
        :filter => [:and, [:eq,:node_binding_rs_id,id()], [:eq,:type,"image"]]
      }
      ret = Model.get_objs(id_handle.createMH(:node),sp_hash).find{|r|r[:external_ref][:image_id] == node_template_ref[:image_id]}
      raise Error.new("Cannot find associated node template") unless ret
      ret
    end
  end
end

