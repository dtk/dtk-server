module XYZ
  module FieldSetInstanceMixin
    module FieldSet
      class << self
        def default(model_name_x)
          ret_cols(model_name_x,:default) do |db_rel|
            non_hidden_columns(db_rel[:columns]) + non_hidden_columns(COMMON_REL_COLUMNS) + virtual_columns_in_fieldset(db_rel[:virtual_columns]) + many_to_one_cols(db_rel)
          end
        end

        def all_real(model_name_x)
          ret_cols(model_name_x,:all_real) do |db_rel|
            real_cols(db_rel) + many_to_one_cols(db_rel)
          end
        end

        def all_settable(model_name_x)
          ret_cols(model_name_x,:all_settabler) do |db_rel|
            real_cols(db_rel) + many_to_one_cols(db_rel) + virtual_settable_cols(db_rel)
          end
        end

        def all_settable_scalar(model_name_x)
          ret_cols(model_name_x,:all_settable_scalar) do |db_rel|
            real_cols(db_rel) + virtual_settable_cols(db_rel)
          end
        end

        def related_columns(field_set,model_name_x)
          model_name = model_name_x.to_sym
          return nil if field_set.nil?
          return nil unless vcolumns = DB_REL_DEF[model_name][:virtual_columns]
          ret = Array.new
          field_set.each do |f|
            next unless vcol_info = vcolumns[f] 
            #special case is :possible_parents
            next unless deps = convert_to_dependencies(model_name,vcol_info[:possible_parents]) || vcol_info[:dependencies]
            #TODO: optimize when two virtual columns join in same info with same conditions
            ret = ret + deps
          end
          ret.empty? ? nil : ret
        end
       private

        def ret_cols(model_name_x,col_type,&block)
          model_name = model_name_x.to_sym
          db_rel = DB_REL_DEF[model_name]
          Fieldsets[col_type] ||= Hash.new
          col_info = Fieldsets[col_type]
          return col_info[model_name] if col_info[model_name]
          col_info[model_name] = block.call(db_rel)
        end

        def convert_to_dependencies(model_name,possible_parents)
          return nil if possible_parents.nil?
          #TODO: migh make geenral utility fn with inject Aux.hash_map
          possible_parents.map do |parent|
            fk_col = DB.ret_parent_id_field_name(DB_REL_DEF[parent],DB_REL_DEF[model_name])
            {
              :model_name => parent,
              :join_cond=>{:id=>"#{model_name}__#{fk_col}".to_sym},
              :cols=>[:id, :display_name, :ref, :ref_num]
            }
          end
        end

        #TBD: may instead put in DB_REL_DEF
        Fieldsets = Hash.new

        def non_hidden_columns(cols_def)
          cols_def.reject{|k,v| v and v[:hidden]}.keys
        end

        def virtual_columns_in_fieldset(cols_def)
          cols_def.reject{|k,v| v and v[:hidden]}.keys
        end

        def real_cols(db_rel)
          db_rel[:columns].keys + COMMON_REL_COLUMNS.keys
        end
        def many_to_one_cols(db_rel)
          (db_rel[:many_to_one]||[]).map{|p|DB.ret_parent_id_field_name(DB_REL_DEF[p],db_rel)}
        end
        def virtual_settable_cols(db_rel)
          (db_rel[:virtual_columns]||[]).map{|vc,vc_info|vc if vc_info[:path]}.compact 
        end
      end
    end
  end
end

  
