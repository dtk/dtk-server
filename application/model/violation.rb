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

    def constraint_list()
      self[:elements].map do |e|
        e.kind_of?(Constraint) ? e : e.constraint_list() 
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
    def self.save(parent,violation_expression,opts={})
      expression_list = ret_expression_list(violation_expression)
      save_list(parent,expression_list,opts)
    end

   
    def self.ret_violations(target_node_id_handles)
      ret = Array.new
      return ret if target_node_id_handles.empty?
      Node.get_violations(target_node_id_handles)
    end
    def self.update_violations(target_node_id_handles)
      ret = Array.new
      saved_violations = ret_violations(target_node_id_handles)
      return ret if saved_violations.empty?
      sample_idh = target_node_id_handles.first

      viol_idhs_to_delete = Array.new
      saved_violations.each do |v|
        raise Error.new("Not treating expression form") unless constraint_hash = v[:expression][:constraint]
        constraint = Constraint.create(constraint_hash)
        vtttype = constraint[:target_type] 
        target_idh = sample_idh.createIDH(:model_name => vt_model_name(vtttype),:id => constraint[:target_id])
        target = {vtttype => target_idh}
        if constraint.evaluate_given_target(target)
          Log.info("violation with id #{v[:id].to_s} no longer applicable; being removed")
          viol_idhs_to_delete << sample_idh.createIDH(:model_name => :violation,:id => v[:id])
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
      return Array.new if expression[:elements].empty?
      return expression unless expression[:logical_op] == :and
      expression[:elements].map do |expr_el|
        if expr_el.kind_of?(Constraint) then expr_el.merge(:violation_target => expression[:violation_target])
        elsif (not expr_el.logical_op == :and) then expr_el
        else expr_el.map{|x|ret_expression_list(x)}
        end
      end.flatten
    end

    def self.save_list(parent,expression_list,opts={})
      #each element of expression_list will either be constraint or a disjunction
      parent_idh = parent.id_handle_with_auth_info()
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
      saved_violations = ret_violations(target_node_id_handles)
      create_rows = prune_duplicate_violations(create_rows,saved_violations)
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

    def self.prune_duplicate_violations(create_rows,saved_violations)
      return create_rows if saved_violations.empty?
      create_rows.reject do |r|
        unless c1 = r[:expression][:constraint]
          Log.error("Not treating expressions of form #{r[:expression].keys.first}")
          next
        end
        saved_violations.find do |sv|
          unless c2 = sv[:expression][:constraint]
            Log.error("Not treating expressions of form #{sv[:expression].keys.first}")
            next
          end
          (r[:severity] == sv[:severity]) and (c1[:id] == c2[:id]) and (c1[:target_id] = c2[:target_id])
        end
      end
    end
  end

  #TODO: unify with Violation class
  class ValidationError < HashObject 
    #TODO: deprecate
=begin
    extend R8Tpl::Utility::I18n
    def self.find_missing_required_attributes(commit_task)
      component_actions = commit_task.component_actions
      ret = Array.new 
      i18n = get_i18n_mappings_for_models(:attribute,:component)
      component_actions.each do |action|
        component_name = i18n_string(i18n,:component, (action[:component]||{})[:display_name])
        node_name = (action[:node]||{})[:display_name]
        node_id = (action[:node]||{})[:id]
        AttributeComplexType.flatten_attribute_list(action[:attributes],:flatten_nil_value=>true).each do |attr|
          #TODO: need to distingusih between legitimate nil value and unset
          next unless attr[:required] and attr[:attribute_value].nil? and (not attr[:port_type] == "input") and (not attr[:dynamic])
          error_input = {
            :attribute_name => i18n_string(i18n,:attribute,attr[:display_name]),
            :component_name => component_name,
            :node_name => node_name,
            :node_id => node_id
          }
          ret <<  MissingRequiredAttribute.new(error_input)
        end
      end
      ret.empty? ? nil : ret
    end
=end
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
      def self.create_from_augmented_attr(attr)
        error_hash = {
          :attribute_id => attr[:id],
          :attribute_name => attr[:display_name],
          :component_name => attr[:component][:display_name],
          :component_id => attr[:component][:id],
          :node_name =>  attr[:node][:display_name],
          :node_id => attr[:node][:id]
        }
        new(error_hash)
      end
      def error_fields()
        [:node_id,:node_name,:component_name,:component_id,:attribute_name,:attribute_id]
      end
    end
  end
end
