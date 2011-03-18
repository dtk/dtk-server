module XYZ
  class ViolationExpression 
    def initialize(logical_op)
      @logical_op = logical_op
      @elements = Array.new
    end

    def <<(expr)
      @elements << expr
      self
    end

    def self.and(*exprs)
      ret = new(:and)
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
  end

 class Violation < Model
    def self.save_expression(parent,violation_expression)
      parent_id = parent.id_handle()
      parent_mn = parent_idh[:model_name]
      raise Error.new("Violation.save not implemented yet when parent has type #{parent_mn}") unless parent.respond_to?(:get_violations_from_db)
      violation_mh = parent_idh.create_childMH(:violation)
      parent_id = parent_id.get_id()
      parent_col = DB.parent_field(parent_mn,:violation)

      saved_violations = parent.get_violations_from_db()
      create_rows = rows.map{|r|r.merge(parent_col => parent_id)}
      prune_already_saved_violations!(create_rows)
      create_from_rows(violation_mh,create_rows)
    end
   private
    def prune_already_saved_violations!(create_rows,saved_violations)
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
