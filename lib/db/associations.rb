
require 'sequel'
require File.expand_path('schema_processing', File.dirname(__FILE__))
# TBD: not clear whetehr this should go here or under models
module XYZ
  class DB
    module Associations

        ########### SchemaProcessing
        include SchemaProcessing unless included_modules.include?(SchemaProcessing)
        def create_table_associations?(db_rel)
          return nil if db_rel[:many_to_one].nil?
      db_rel[:many_to_one].each{|parent_rel_type|
       #TDB error messages if anything null
       parent_db_rel = DB_REL_DEF[parent_rel_type]
      foreign_key_field = ret_parent_id_field_name(parent_db_rel, db_rel)
      #TBD: may put in null constraints, but this must be conditional
      add_foreign_key? db_rel, foreign_key_field, parent_db_rel, on_delete: :cascade, on_update: :cascade, type: ID_TYPES[:id]
    }
    nil
        end

        def add_foreign_key(db_rel, foreign_key_field, db_rel_pointed_to, opts = {})
          table_pt = db_rel_pointed_to.schema_table_symbol()
          @db.alter_table(db_rel.schema_table_symbol) do
       add_foreign_key foreign_key_field, table_pt, opts
    end
    nil
        end

        def add_foreign_key?(db_rel, foreign_key_field, db_rel_pointed_to, opts = {})
          unless foreign_key_exists?(db_rel, foreign_key_field, db_rel_pointed_to)
            add_foreign_key(db_rel, foreign_key_field, db_rel_pointed_to, opts)
    end
        end
      ########### end: SchemaProcessing
    end
  end

  # used during clone operation to help appropriately set foreign key refs
  class CloneHelper
    @@fk_refs = {}
    def self.add_foreign_key_info(fk_relation_type, fk_col, fk_ref_relation_type)
      # ancestor_id is processed in special way
      return nil if fk_col == :ancestor_id

      @@fk_refs[fk_ref_relation_type] ||= {}
      @@fk_refs[fk_ref_relation_type][fk_relation_type] ||= {}
      @@fk_refs[fk_ref_relation_type][fk_relation_type][fk_col] = true
    end

    def initialize(db)
      @db = db
      @id_mapping_in_clone = {}
    end

    def update(c, db_rel, old_id, new_id, _scalar_assignments)
      relation_type = db_rel[:relation_type]
      enter_id_mapping_if_fk_ref(relation_type, old_id, new_id, c)
    end

    def set_foreign_keys_to_right_values
      @id_mapping_in_clone.each_pair{|old_id, info|
   next unless fk_info = @@fk_refs[info[:relation_type]]
   fk_info.each_pair{|fk_relation_type, cols|
     cols.keys.each{|col|
       @db.update(fk_relation_type, info[:c], { col => info[:new_id] }, { col => old_id })
           }
         }
      }
    end

    private

    def enter_id_mapping_if_fk_ref(relation_type, old_id, new_id, c)
      return nil unless CloneHelper.foreign_key_ref?(relation_type)
      @id_mapping_in_clone[old_id] = { new_id: new_id, c: c, relation_type: relation_type }
    end

    def self.foreign_key_ref?(relation_type)
       @@fk_refs[relation_type] ? true : nil
    end
  end
end
