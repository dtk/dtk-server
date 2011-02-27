module XYZ
  class Constraints < Model
#    set_relation_name(:constraint,:constraint)
      #######################
      ######### Model apis
    def evaluate(source_id_handle,target_id_handle)
      pp [:constraints,self]
      unless source_id_handle[:model_name] == :component
        Log.error("not implemented yet: treatment of constraint with source_object of type #{source_source_id_handle[:model_name]}")
        return true
      end

      return false unless evaluate_component_constraints(source_id_handle,target_id_handle)
      #TODO: process node constraint
      true
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

    def evaluate_port_constraints(other_end_idh)
      constraints = self[:component_constraints]
      constraints.each do |constraint|
        match = PortConstraint.evaluate(constraint,other_end_idh)
        pp [:debug,match]
        return false if match.empty?
      end
      true
    end

   private
    module PortConstraint
      def self.evaluate(constraint,other_end_idh)
        convert_from_virtual_object_form(constraint)
=begin
        [{
           :model_name => :attribute,
           :filter => [:and,[:eq,:id, other_end_idh.get_id()]],
           :cols=>[:id,:component_component_id]
         },
         {
           :model_name => :component,
           :join_type => :inner,
           :filter => [:and,[:eq,:component_type,component_type]]
           :join_cond=>{:id=> :attribute__component_component_id},
           :cols=>[:id, :display_name,:node_node_id]
         }
        ]
=end
      end
      private
      #converts from form that acts as if attributes are directly attached to component  
      def self.convert_from_virtual_object_form(vo_form)
        pp [:debug,HashSearchPattern.break_filter_into_conjunctions(vo_form[:filter])]
      end
    end

    #TODO: unify the different contraint variants
    def evaluate_component_constraints(component_id_handle,target_id_handle)
      return true unless constraints = self[:component_constraints]
      component_mh = component_id_handle.createMH()
      node_id =
        case target_id_handle[:model_name]
         when :component 
          target_id_handle.create_object().get_containing_node_id()
         when :node 
          target_id_handle.get_id()
         else
          Log.error("no implemented yet: treatment of component contraint with target of type #{target_id_handle[:model_name]}")
          return true
        end
      unless node_id
        Log.error("cannot determine source object's containing node id")
        return true
      end
      #TODO: for evaluate just and the filters and use one column as return id; for getting errors individually run negation of each and
      #run columns through an "i18n template"; would want though constants captured through column aliases
      constraints.each do |sp_hash|
        sp_hash = HashSearchPattern.add_to_filter(sp_hash, [:eq,:node_node_id,node_id])
        match = Model.get_objects_from_sp_hash(component_mh,sp_hash)
        pp [:debug,match]
        return false if match.empty?
      end
      true
    end
  end
end

