module DTK; class NodeModuleDSL
  module UpdateModelMixin
    def update_model(opts={})
      db_update_hash = db_update_form(cmps_hash,stored_cmps_hash,module_branch_idh)
      Model.input_hash_content_into_model(container_idh,db_update_hash)
    end

   private
    def db_update_form(cmps_input_hash,non_complete_cmps_input_hash,module_branch_idh)
      # TODO: look at use of new recursive delete capability; this may be needed to handle attributes correctly
      mark_as_complete_constraint = {
        :module_branch_id=>module_branch_idh.get_id(), #so only delete extra components that belong to same module
        :node_node_id => nil #so only delete component templates and not component instances
      }
      cmp_db_update_hash = cmps_input_hash.inject(DBUpdateHash.new) do |h,(ref,hash_assigns)|
        h.merge(ref => db_update_form_aux(:component,hash_assigns))
      end.mark_as_complete(mark_as_complete_constraint)
      {"component" => cmp_db_update_hash.merge(non_complete_cmps_input_hash)}
    end

    def db_update_form_aux(model_name,hash_assigns)
      # TODO: think the key -> key.to_sym is not needed because they are keys
      ret = DBUpdateHash.new
      children_model_names = DB_REL_DEF[model_name][:one_to_many]||[]
      hash_assigns.each do |key,child_hash|
        key = key.to_sym
        if children_model_names.include?(key)
          child_model_name = key
          ret[key] = child_hash.inject(DBUpdateHash.new) do |h,(ref,child_hash_assigns)|
            h.merge(ref => db_update_form_aux(child_model_name,child_hash_assigns))
          end
          ret[key].mark_as_complete()
        else
          ret[key] = child_hash
        end
      end
      # mark as complete any child that does not appear in hash_assigns
      (children_model_names - hash_assigns.keys.map{|k|k.to_sym}).each do |key|
        ret[key] = DBUpdateHash.new().mark_as_complete()
      end
      ret
    end
  end
end; end

