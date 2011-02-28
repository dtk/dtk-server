module XYZ
  class Dependency < Model
    def self.create(hash_scalar_values,c,relation_type_x=model_name(),id_handle=nil)
      if hash_scalar_values[:type] == "component" and hash_scalar_values[:attribute_attribute_id]
        PortConstraint.new(hash_scalar_values,c,relation_type_x,id_handle)
      else
        Error.new("unexpetced dependency type")
      end
    end

   private
    def initialize(hash_scalar_values,c,relation_type_x=model_name(),id_handle=nil)
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
    #######################
    ######### Model apis
    def self.evaluate_constraints_given_target(constraints,target)
      constraints.each do |constraint|
        match = constraint.evaluate_given_target(target)
        pp [:debug,match]
        return false if match.empty?
      end
      true
    end
  end

  module ConstraintMixin
    def initialize(hash_scalar_values,c,relation_type_x=model_name(),id_handle=nil)
      super
    end
  end
  class ComponentConstraint < Dependency
    include ConstraintMixin
   private
    #converts from form that acts as if attributes are directly attached to component  
    def ret_join_array()
      real = Array.new
      virtual = Array.new
      real_cols = real_component_columns()
      conjunctions = ((self[:search_pattern]||{}[:filter])||[]).break_filter_into_conjunctions() 
      conjunctions.each do |conjunction|
        if real_cols.include?(ret_col_in_comparison(conjunction))
          real << conjunction
        else 
          virtual << conjunction
        end
      end
      if virtual.empty?
        [{
           :model_name => :component,
           :filter => [:and] + real,
           :join_type => :inner,
           :join_cond => {:id => :attribute__component_component_id},
           :cols => [:id,:display_name]
         }]
      else
        #TODO: STUB
        [{
           :model_name => :component,
           :filter => [:and] + real,
           :join_type => :inner,
           :join_cond => {:id => :attribute__component_component_id},
           :cols => [:id,:display_name]
         }]
      end
    end

    def real_component_columns()
      @@real_component_columns ||= DB_REL_DEF[:component][:columns].keys
    end
  end

  class PortConstraint < ComponentConstraint
    include ConstraintMixin
    def evaluate_given_target(target)
      other_end_idh  = target[:target_port_id_handle]
      join_array = ret_join_array()
      model_handle = other_end_idh.createMH(:attribute)
      base_sp_hash = {
        :model_name => :attribute,
        :filter => [:and,[:eq,:id, other_end_idh.get_id()]],
        :cols => [:id,:component_component_id]
      }
      base_sp = SearchPatternSimple.new(base_sp_hash)
      dataset = SQL::DataSetSearchPattern.create_dataset_from_join_array(model_handle,base_sp,join_array)
      dataset.all.first
    end
  end
end

