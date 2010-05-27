module XYZ
  #class methods
  module MigrationMethods #methods that can be called within a migration

    def set_relation_as_top()
      @is_top = true
    end
    def top?()
      @is_top
    end

    def set_relation_name(*arg)
      @is_top = nil
      @relation_type = Local.ret_relation_type(self)
      @db_rel = convert_to_db_rel_form(*arg)
      @db_rel[:relation_type] = @relation_type
      @db_rel[:many_to_one] = []
      @db_rel[:one_to_many] = []
      @db_rel[:columns] = {}
      @db_rel[:model_class] = self
      @virtual_columns = {}
      nil
    end

    def many_to_one(*target_relation_types)
      @db_rel[:many_to_one] = target_relation_types
      nil
    end

    def one_to_many(*target_relation_types)
      @db_rel[:one_to_many] = target_relation_types
      nil
    end

    def column(col_name,col_type,opts={})
      @db_rel[:columns][col_name] = {:type => col_type}.merge(opts)
      nil 
    end

    def virtual_column(col)
     @virtual_columns[col] = true 
    end

    #TBD: hardwired to ref column id on target table
    def foreign_key(col_name,target_rel_type,opts={})
      @db_rel[:columns][col_name] = {:type => ID_TYPES[:id], :foreign_key_rel_type => target_rel_type}.merge(opts)
      CloneHelper.add_foreign_key_info(@relation_type,col_name,target_rel_type)
      nil 
    end

    def has_ancestor_field()
      @db_rel[:has_ancestor_field] = true
      foreign_key(:ancestor_id,@relation_type,FK_SET_NULL_OPT)
    end

   private

    module Local
      def self.ret_relation_type(klass)
        Aux.underscore(Aux.demodulize(klass.to_s)).to_sym
      end
    end
  end
end

