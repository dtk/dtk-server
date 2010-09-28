module XYZ
  module FieldSetInstanceMixin
    module FieldSet
      class << self
        def default(model_name_x)
          model_name = model_name_x.to_sym
          Fieldsets[:default][model_name] ||= non_hidden_columns(DB_REL_DEF[model_name][:columns]) + non_hidden_columns(COMMON_REL_COLUMNS) + virtual_columns_in_fieldset(DB_REL_DEF[model_name][:virtual_columns]) + many_to_one_cols(DB_REL_DEF[model_name])
        end

        def all_actual(model_name_x)
          model_name = model_name_x.to_sym
          Fieldsets[:all_actual][model_name] ||= DB_REL_DEF[model_name][:columns].keys + COMMON_REL_COLUMNS.keys + many_to_one_cols(DB_REL_DEF[model_name])
        end

        def related_columns(field_set,model_name_x)
          model_name = model_name_x.to_sym
          return nil if field_set.nil?
          return nil unless vcolumns = DB_REL_DEF[model_name][:virtual_columns]
          ret = Hash.new
          field_set.each do |f|
            next unless vcol_info = vcolumns[f] 
            #special case is :possible_parents
            next unless deps = convert_to_dependencies(model_name,vcol_info[:possible_parents]) || vcol_info[:dependencies]
            deps.each do |model_name,info|
              if ret[model_name]
                update_matching_dep_table!(ret,model_name,info)
              else 
                ret[model_name] = [info]
              end
            end
          end
          ret.empty? ? nil : ret
        end
       private

        def convert_to_dependencies(model_name,possible_parents)
          return nil if possible_parents.nil?
          #TODO: migh make geenral utility fn with inject Aux.hash_map
          possible_parents.inject({}) do |h,o|
            fk_col = DB.ret_parent_id_field_name(DB_REL_DEF[o],DB_REL_DEF[model_name])
            val = {
              :join_cond=>{:id=>"#{model_name}__#{fk_col}".to_sym},
              :cols=>[:id, :display_name, :ref, :ref_num]}
            h.merge(o => val)
          end
        end

        def update_matching_dep_table!(ret,model_name,new_info)
          #TODO: validate whether == works on nested hashes
          if ret[model_name][:join_cond] == info[:join_cond]
            if ret[model_name][:cols] or info[:cols]
              #union results
              ret[model_name][:cols] = (ret[model_name][:cols]||[])|(info[:cols]||[])
            end
          else
            ret[model_name] << [info]
          end
        end

        #TBD: may instaed put in DB_REL_DEF
        Fieldsets = {:default => Hash.new,:all_actual => Hash.new}    

        def non_hidden_columns(cols_def)
          cols_def.reject{|k,v| v and v[:hidden]}.keys
        end

        def virtual_columns_in_fieldset(cols_def)
          cols_def.reject{|k,v| v and v[:hidden]}.keys
        end
        def many_to_one_cols(db_rel)
          (db_rel[:many_to_one]||[]).map{|p|DB.ret_parent_id_field_name(DB_REL_DEF[p],db_rel)}
        end
      end
    end
  end
end

  
