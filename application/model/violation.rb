module XYZ
  class ViolationExpression 
    attr_reader :elements,:logical_op,:violation_target
    def initialize(violation_target,logical_op)
      @violation_target = violation_target
      @logical_op = logical_op
      @elements = Array.new
    end

    def <<(expr)
      @elements << expr
      self
    end

    def self.and(*exprs)
      vt = exprs.first.violation_target
      exprs[1..exprs.size-1].map do |e|
        unless exprs.first.eq_violation_target?(e)
          raise Error.new("Not supported conjunction of expressions with different violation_targets")
        end
      end
      ret = new(vt,:and)
      exprs.each{|e|ret << e}
      ret
    end

    def empty?()
      @elements.empty?()
    end

    def pp_form()
      Array.new if @elements.empty?
      args = @elements.map{|x|x.kind_of?(Constraint) ? x[:description] : x.pp_form}
      args.size == 1 ? args.first : [@logical_op] + args 
    end
    
    def self.target_type(vt)
      vt.keys.first
    end

    def self.target_id(vt)
      vt.values.first.get_id()
    end
   protected
    def eq_violation_target?(violation_expression)
      ve2 = violation_expression #just for succinctness
      (violation_target_type() == ve2.violation_target_type()) and (violation_target_id() == ve2.violation_target_id())
    end
    def violation_target_type()
      self.class.target_type(violation_target)
    end
    def violation_target_id()
      self.class.target_id(violation_target)
    end
  end

  class Violation < Model
    def self.save_expression(parent,violation_expression)
      expression_list = ret_expression_list(violation_expression)
      save_atomic_expressions(parent,expression_list)
    end
   private

    def self.ret_expression_list(expression)
      return expression unless expression.logical_op == :and
      expression.elements.map do |expr_el|
        if expr_el.kind_of?(Constraint) then expr_el.merge(:violation_target => expression.violation_target)
        elsif (not expr_el.logical_op == :and) then expr_el
        else expr_el.map{|x|ret_expression_list(x)}
        end
      end.flatten
    end

    def self.save_atomic_expressions(parent,expression_list)
      #each element of expression_list will either be constraint or a disjunction
      parent_idh = parent.id_handle()
      parent_mn = parent_idh[:model_name]
      unless parent.respond_to?(:get_violations_from_db)
      Log.error("Violation.save_atomic_expressions not implemented yet when parent has type #{parent_mn}") 
        return
      end
      violation_mh = parent_idh.create_childMH(:violation)
      parent_id = parent_idh.get_id()
      parent_col = DB.parent_field(parent_mn,:violation)
            
      create_rows = expression_list.map do |e|
        sample_constraint = e.kind_of?(Constraint) ? e : e.elements.first
        vt = e.kind_of?(Constraint) ? e[:violation_target] : e.violation_target
        raise Error.new("target type not treated") unless ViolationExpression.target_type(vt) == :target_node_id_handle
        #TODO: assumes that under or is constraint elements
        vexpr = e.kind_of?(Constraint) ? ["and",e[:id]] : ["or"] + e.elements.map{|x|x[:id]} 
        description = e.kind_of?(Constraint) ? e[:description] : e.elements.map{|x|x[:description]}.join(" or ")
        ref = "violation" #TODO: stub
        {
          :ref => ref,
          parent_col => parent_id,
          :severity => sample_constraint[:severity],
          :target_node_id => ViolationExpression.target_id(vt),
          :expression => vexpr,
          :description => description
        }
      end
      saved_violations = parent.get_violations_from_db()
      prune_already_saved_violations!(create_rows,saved_violations)
      create_from_rows(violation_mh,create_rows, :convert => true)
    end
    def self.prune_already_saved_violations!(create_rows,saved_violations)
      #TODO: stub
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
