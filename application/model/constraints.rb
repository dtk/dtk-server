module XYZ
  class Constraints
    def initialize(logical_op,dependency_list)
      @logical_op = logical_op
      @constraints = dependency_list.map{|dep|Constraint.create(dep)}
    end
    def evaluate_given_target(target)
      return true if @constraints.empty?
      @constraints.each do |constraint|
        match = constraint.evaluate_given_target(target)
        pp [:debug,match] unless match.nil?
        case @logical_op
          when :or
            return true unless match.nil?
          when :and
            return false if match.nil?
        end
      end
       case @logical_op
         when :or then false
         when :and then true
       end
    end

    def ret_violations(target)
      violations = @constraints.map do |constraint|
        match = constraint.evaluate_given_target(target)
        constraint[:description] if match.nil?
      end.compact
      return Array.new if violations.empty?
      [@logical_op] + violations
    end

    module Macro
      def self.required_components(component_list)
        component_list.map do |cmp|
          hash = {
            :filter => [:and, [:eq, :component_type, cmp]],
            :columns => [cmp => :component_type]
          }
          string_symbol_form(hash)
        end
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
      else
        Error.new("unexpetced dependency type")
      end
    end
    def evaluate_given_target(target)
      dataset = create_dataset(target)
      dataset.all.first
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

  class ComponentConstraint < Constraint
   private
    #converts from form that acts as if attributes are directly attached to component  
    def ret_join_array()
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

      direct_component = {
        :model_name => :component,
        :join_type => :inner,
        :join_cond => {:id => :attribute__component_component_id},
        :cols => [:id,:display_name]
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

  class PortConstraint < ComponentConstraint
   private
    def create_dataset(target)
      other_end_idh  = target[:target_port_id_handle]
      join_array = ret_join_array()
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



