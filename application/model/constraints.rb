#TODO: simplify by changing target arg to be just idh
module XYZ
  class Constraints
    def initialize(logical_op=:and,constraints=[])
      @logical_op = logical_op
      @constraints = constraints
    end
    def evaluate_given_target(target,opts={})
      ret = evaluate_given_target_just_eval(target)
      return ret if ret
      if opts[:raise_error_when_violation]
        violations = ret_violations(target)
        raise ErrorConstraintViolations.new(violations)
      end
      ret
    end
  private
    def evaluate_given_target_just_eval(target)
      return true if @constraints.empty?
      @constraints.each do |constraint|
        constraint_holds = constraint.evaluate_given_target(target)
        case @logical_op
          when :or
            return true if constraint_holds
          when :and
            return false unless constraint_holds
        end
      end
      case @logical_op
        when :or then false
        when :and then true
      end
    end
   public
    def ret_violations(target)
      violations = @constraints.map do |constraint|
        constraint_holds = constraint.evaluate_given_target(target)
        constraint[:description] unless constraint_holds
      end.compact
      return Array.new if violations.empty?
      [@logical_op] + violations
    end

    module Macro
      #TODO: so if can move over so Macro under Constraint and produces constraint not a sp
      def self.required_component(component_type)
        hash = {
          :filter => [:and, [:eq, :component_type, component_type]],
        }
        string_symbol_form(hash)
      end
     private
      def self.string_symbol_form(term)
        if term.kind_of?(Symbol)
          ":#{term}"
        elsif term.kind_of?(String)
          term
        elsif term.kind_of?(Hash)
          term.inject({}){|h,kv|h.merge(string_symbol_form(kv[0]) => string_symbol_form(kv[1]))}
        elsif term.kind_of?(Array) 
          term.map{|t|string_symbol_form(t)}
        else
          Log.error("unexpected form for term #{term.inspect}")
        end
      end
    end
  end

  class Constraint < HashObject
    def self.create(dependency)
      if dependency[:type] == "component" and dependency[:attribute_attribute_id]
        PortConstraint.new(dependency)
      elsif dependency[:type] == "component" and dependency[:component_component_id]
        ComponentConstraint.new(dependency)
      else
        raise Error.new("unexpected dependency type")
      end
    end
    def evaluate_given_target(target)
      dataset = create_dataset(target)
      is_empty = dataset.all.empty?
      self[:negate] ? is_empty : (not is_empty)
    end

    module Macro
      def self.only_one_per_node(component_type)
        dep = {
          :description => "Only one component of type #{component_type} can be on a node",
          :negate => true,
          :search_pattern => {
            :filter => [:and, [:eq, :component_type, component_type]],
          }
        }
        ComponentConstraint.new(dep)
      end
    end

   private
    def initialize(dependency)
      super
      reformat_search_pattern!()
    end
    def reformat_search_pattern!()
      self[:search_pattern] = search_pattern && SearchPattern.create_just_filter(search_pattern)
      self
    end
    def search_pattern()
      self[:search_pattern]
    end
   public    
  end

  module ProcessVirtualComponentMixin
    #converts from form that acts as if attributes are directly attached to component  
    def ret_join_array(join_cond)
      real = Array.new
      virtual = Array.new
      real_cols = real_component_columns()
      search_pattern.break_filter_into_conjunctions().each do |conjunction|
        parsed_comparision = SearchPatternSimple.ret_parsed_comparison(conjunction)
        if real_cols.include?(parsed_comparision[:col])
          real << conjunction
        else 
          virtual << parsed_comparision
        end
      end

      cols = [:id,:display_name]
      cols << join_cond.keys.first unless cols.include?(join_cond.keys.first)
      direct_component = {
        :model_name => :component,
        :join_type => :inner,
        :join_cond => join_cond,
        :cols => cols
      }
      direct_component.merge!(:filter => [:and] + real) unless real.empty?

      if virtual.empty?
        [direct_component]
      else
        [direct_component] +
          virtual.map do |v|
          {
            :model_name => :attribute,
            :alias => v[:col],
            :filter => [v[:op],v[:col],v[:constant]],
            :join_type => :inner,
            :join_cond => {:component_component_id => :component__id},
            :cols => [:id,:display_name]
          }
        end
      end
    end

    def real_component_columns()
      @@real_component_columns ||= DB_REL_DEF[:component][:columns].keys
    end
  end

  class ComponentConstraint < Constraint
   private
    include ProcessVirtualComponentMixin
    def create_dataset(target)
      node_idh  = 
        if target[:target_node_id_handle]
          target[:target_node_id_handle]
        elsif target[:target_component_id_handle]
          target[:target_component_id_handle].get_containing_node_id()
        else
          raise Error.new("unexpected target")
        end
      join_cond = {:node_node_id => :node__id}
      join_array = ret_join_array(join_cond)
      model_handle = node_idh.createMH(:node)
      base_sp_hash = {
        :model_name => :node,
        :filter => [:and,[:eq,:id, node_idh.get_id()]],
        :cols => [:id]
      }
      base_sp = SearchPatternSimple.new(base_sp_hash)
      SQL::DataSetSearchPattern.create_dataset_from_join_array(model_handle,base_sp,join_array)
    end
  end

  class PortConstraint < Constraint
   private
    include ProcessVirtualComponentMixin
    def create_dataset(target)
      other_end_idh  = target[:target_port_id_handle]
      join_cond = {:id => :attribute__component_component_id}
      join_array = ret_join_array(join_cond)
      model_handle = other_end_idh.createMH(:attribute)
      base_sp_hash = {
        :model_name => :attribute,
        :filter => [:and,[:eq,:id, other_end_idh.get_id()]],
        :cols => [:id,:component_component_id]
      }
      base_sp = SearchPatternSimple.new(base_sp_hash)
      SQL::DataSetSearchPattern.create_dataset_from_join_array(model_handle,base_sp,join_array)
    end
  end
end



