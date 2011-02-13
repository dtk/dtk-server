module XYZ
  class Constraints < Model
#    set_relation_name(:constraint,:constraint)
      #######################
      ######### Model apis
    def evaluate(source_id_handle,target_id_handle)
      pp [:constraints,self]
      unless source_id_handle[:model_name] == :component
        Log.error("no implemented yet: treatment of contraint with source_object of type #{source_source_id_handle[:model_name]}")
        return true
      end

      return false unless evaluate_component_constraints(source_id_handle,target_id_handle)
      #TODO: process node constraint
      true
    end
   private
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

