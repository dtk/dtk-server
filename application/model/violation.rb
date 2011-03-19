module XYZ
  class ViolationExpression < HashObject 
    def initialize(violation_target,logical_op)
      hash = {
        :violation_target => ViolationTarget.new(violation_target),
        :logical_op => logical_op,
        :elements => Array.new
      }
      super(hash)
    end

    def <<(expr)
      self[:elements] << expr
      self
    end

    def constrainit_list
      self[:elements].map do |e|
        e.kind_of?(Constraint) ? e : e.constrainit_list 
      end.flatten
    end

    def self.and(*exprs)
      vt = exprs.first.violation_target
      exprs[1..exprs.size-1].map do |e|
        unless vt == e[:violation_target]
          raise Error.new("Not supported conjunction of expressions with different violation_targets")
        end
      end
      ret = new(vt,:and)
      exprs.each{|e|ret << e}
      ret
    end

    def empty?()
      self[:elements].empty?()
    end

    def pp_form()
      Array.new if self[:elements].empty?
      args = self[:elements].map{|x|x.kind_of?(Constraint) ? x[:description] : x.pp_form}
      args.size == 1 ? args.first : [self[:logical_op]] + args 
    end
  end

  class ViolationTarget < HashObject
    def initialize(key_idh)
      hash = {
        :type => key_idh.keys.first,
        :id_handle => key_idh.values.first,
        :id => key_idh.values.first.get_id()
      }
      super(hash)
    end

    def ==(vt2)
      (self[:type] == vt2[:type]) and  (self[:id] == vt2[:id])
    end
  end

  class Violation < Model
    def self.save_expression(parent,violation_expression)
      expression_list = ret_expression_list(violation_expression)
      save_atomic_expressions(parent,expression_list)
    end

    #This function delete
    def self.ret_and_update_violations(target_node_id_handles)
      ret = Array.new
      return ret if target_node_id_handles.empty?
      sample_idh = target_node_id_handles.first
      saved_violations = Node.get_violations(target_node_id_handles)
      viol_idhs_to_delete = Array.new

      saved_violations.each do |v|
        raise Error.new("Not treating expression form") unless constraint_hash = v[:expression][:constraint]
        constraint = Constraint.create(constraint_hash)
        vtttype = constraint[:target_type] 
        target_idh = sample_idh.createIDH(:model_name => vt_model_name(vtttype),:id => constraint[:target_id])
        target = {vtttype => target_idh}
        if constraint.evaluate_given_target(target)
          Log.info("violation with id #{v[:id].to_s} no longer applicable; being removed")
          viol_idhs_to_delete << violation_mh.createIDH(:id => v[:id])
        else
          ret << v
        end
      end
      delete_instances(viol_idhs_to_delete) unless viol_idhs_to_delete.empty?
      ret
    end

   private
    def self.vt_model_name(vtttype)
      ret = VTModelName[vtttype]
      return ret if ret
      raise Error.new("Unexpected violaition target type #{vtttype}")
    end
    VTModelName = {
      "target_node_id_handle" => :node
    }
    def self.ret_expression_list(expression)
      return expression unless expression[:logical_op] == :and
      expression[:elements].map do |expr_el|
        if expr_el.kind_of?(Constraint) then expr_el.merge(:violation_target => expression[:violation_target])
        elsif (not expr_el.logical_op == :and) then expr_el
        else expr_el.map{|x|ret_expression_list(x)}
        end
      end.flatten
    end

    def self.save_atomic_expressions(parent,expression_list)
      #each element of expression_list will either be constraint or a disjunction
      parent_idh = parent.id_handle()
      parent_mn = parent_idh[:model_name]
      violation_mh = parent_idh.create_childMH(:violation)
      parent_id = parent_idh.get_id()
      parent_col = DB.parent_field(parent_mn,:violation)
         
      create_rows = Array.new
      target_node_id_handles = Array.new 
      expression_list.each do |e|
        sample_constraint = e.kind_of?(Constraint) ? e : e.constraint_list.first
        vt = e[:violation_target]
        raise Error.new("target type #{vt[:type]} not treated") unless vt[:type] == "target_node_id_handle"
        description = e.kind_of?(Constraint) ? e[:description] : e[:elements].map{|x|x[:description]}.join(" or ")
        ref = "violation" #TODO: stub
        new_item = {
          :ref => ref,
          parent_col => parent_id,
          :severity => sample_constraint[:severity],
          :target_node_id => vt[:id],
          :expression => violation_expression_for_db(e),
          :description => description
        }
        create_rows << new_item
        target_node_id_handles << vt[:id_handle]
      end
      saved_violations = ret_and_update_violations(target_node_id_handles)
      prune_duplicate_violations!(create_rows,saved_violations)
      create_from_rows(violation_mh,create_rows, :convert => true) unless create_rows.empty?
    end

    def self.violation_expression_for_db(expr)
      raise Error.new("Violation expression form not treated") unless expr.kind_of?(Constraint)
      {
        :constraint => {
          :type => expr[:type],
          :component_component_id => expr[:component_component_id],
          :attribute_attribute_id => expr[:attribute_attribute_id],
          :negate => expr[:negate],
          :search_pattern => SearchPattern.process_symbols(expr[:search_pattern]),
          :target_type => expr[:violation_target][:type],
          :target_id => expr[:violation_target][:id],
          :id => expr[:id]
        }
      }
    end

    def self.prune_duplicate_violations!(create_rows,saved_violations)
      #TODO: stub
      pp [:create_rows,create_rows]
      pp [:saved_violations,saved_violations]
      create_rows
    end
  end

  class ValidationError < HashObject 
    def self.find_missing_required_attributes(commit_task)
      component_actions = commit_task.component_actions
      ret = Array.new 
      component_actions.each do |action|
        action[:attributes].each do |attr|
          #TODO: need to distingusih between legitimate nil value and unset
          if attr[:required] and attr[:attribute_value].nil?
            error_input =
              {:external_ref => attr[:external_ref],
              :attribute_id => attr[:id],
              :component_id => (action[:component]||{})[:id]
            }
            ret <<  MissingRequiredAttribute.new(error_input)
            x=1
          end
        end
      end
      ret.empty? ? nil : ret
    end

    def self.debug_inspect(error_list)
      ret = ""
      error_list.each{|e| ret << "#{e.class.to_s}: #{e.inspect}\n"}
      ret
    end
   private
    def initialize(hash)
      super(error_fields.inject({}){|ret,f|hash.has_key?(f) ? ret.merge(f => hash[f]) : ret})
    end
    def error_fields()
      Array.new
    end
   public
    class MissingRequiredAttribute < ValidationError
      def error_fields()
        [:external_ref,:attribute_id,:component_id,:node_id]
      end
    end
  end
end
