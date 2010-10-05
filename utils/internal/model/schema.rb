
#TODO: move these to admin functions and lose notion of schema/data for the core model
#Core model should be just everything that is universal to interact with objects including
#base field defs for id,date_created/modified, created_by user, modified_user, etc

require File.expand_path('schema/migration_methods', File.dirname(__FILE__))
module XYZ
  #class methods
  #TODO partition into public and private
  module ModelSchemaClassMixins
    def set_relation_as_top()
      @is_top = true
    end
    def top?()
      @is_top
    end

    def set_relation_name(*arg)
      @is_top = nil
      @relation_type = ret_relation_type(self)
      @db_rel = convert_to_db_rel_form(*arg)
      @db_rel[:relation_type] = @relation_type
      @db_rel[:many_to_one] = []
      @db_rel[:one_to_many] = []
      @db_rel[:columns] = {}
      @db_rel[:virtual_columns] = {}
      @db_rel[:model_class] = self
    end
    
    attr_reader :db_rel

    def many_to_one(*target_relation_types)
      @db_rel[:many_to_one] = target_relation_types
    end

    def one_to_many(*target_relation_types)
      @db_rel[:one_to_many] = target_relation_types
    end

    def column(col_name,col_type,opts={})
      @db_rel[:columns][col_name] = {:type => col_type}.merge(opts)
    end

    def virtual_column(col_name,opts={})
      @db_rel[:virtual_columns][col_name] = opts
    end

    #TBD: hardwired to ref column id on target table
    def foreign_key(col_name,target_rel_type,opts={})
      @db_rel[:columns][col_name] = {:type => ID_TYPES[:id], :foreign_key_rel_type => target_rel_type}.merge(opts)
      CloneHelper.add_foreign_key_info(@relation_type,col_name,target_rel_type)
    end

    def has_ancestor_field()
      @db_rel[:has_ancestor_field] = true
      foreign_key(:ancestor_id,@relation_type,FK_SET_NULL_OPT)
    end

    def ret_relation_type(klass)
      Aux.underscore(Aux.demodulize(klass.to_s)).to_sym
    end

    #------common column defs -----------
    #for external refs
    def external_ref_column_defs()
      column :external_ref, :json
    end

    #for data source attributes
    def ds_column_defs(*names)
      names.each{|n|ds_column_def(n)}
    end
    def ds_column_def(name)
      if name == :ds_attributes
        column :ds_attributes, :json
      elsif  name == :ds_key
        #TODO: should this be commented out?: :default => '' so when do 'prune inventory' this column not null
        column :ds_key, :varchar, :default => '', :hidden => true 
      elsif  name == :data_source
        column :data_source, :varchar, :size => 25
      elsif  name == :ds_source_obj_type
        column :ds_source_obj_type, :varchar, :size => 25
      end
    end
    #------common column defs -----------
    include MigrationMethods

      #gets over written for classes with data source attributes
      def ds_attributes(attr_list)
       attr_list
      end
      #gets over written for classes that restrict children
      def is_ds_subobject?(relation_type)
        true
      end

      def set_db_for_all_models(db)
        Model.set_db(db)
        #TODO: see if we can remove needing to link all children of Model
        models.each{|model| model.set_db(db)}
        #infra tables
        ContextTable.set_db(db)
        IDInfoTable.set_db(db)
      end

      def setup_infrastructure_tables?(db)
        ContextTable.create?()
        ContextTable.create_default_contexts?()

        IDInfoTable.create_table?()

        db.setup_infrastructure_extras()
      end

      def migrate_all_models(direction)
        # order is important
        concrete_models = models.reject {|m| m.top?}
        concrete_models.each do |model| 
          model.create_column_defs_common_fields?(direction) 
        end
        concrete_models.each{|model| model.apply_migration_defs(direction)}
        concrete_models.each{|model| model.set_global_db_rel_info()}
        concrete_models.each do |model| 
          model.create_column_defs_specific_fields?(direction) 
        end
        concrete_models.each{|model|model.create_associations?(direction)}
      end

      def initialize_all_models(db)
        set_db_for_all_models(db)
        concrete_models = models.reject {|m| m.top?}
        concrete_models.each{|model| model.apply_migration_defs(:up)}
        concrete_models.each{|model| model.set_global_db_rel_info()}
      end
     #######
     protected

      def create_column_defs_common_fields?(direction)
        create_table_common_fields?(@db_rel) if direction == :up
      end

      def apply_migration_defs(direction)
        case direction
          when :up
            up()
          when :down
            down()
        end
      end
    
      def create_column_defs_specific_fields?(direction)
        case direction
          when :up
            create_table_specific_fields?(@db_rel)
          when :down
            #TBD: not implemented yet
        end
      end

      def create_associations?(direction)
        case direction
          when :up
            @db.create_table_associations?(@db_rel)
          when :down
            #TBD: not implemented yet
        end
      end

      def set_global_db_rel_info()
        DB_REL_DEF[@relation_type] = @db_rel
      end

      def set_db(db)
        @db = db
      end

     private

      def create_table_common_fields?(db_rel)
        create_schema_for_db_rel?(db_rel)
        seq_ref = @db.ret_sequence_ref(TOP_LOCAL_ID_SEQ)
        @db.create_table?(db_rel) do
          foreign_key CONTEXT_ID, CONTEXT_TABLE.schema_table_symbol, FK_CASCADE_OPT.merge({:null => false,:type =>  ID_TYPES[:context_id]})
          primary_key :id, :type => ID_TYPES[:id], :null => false
          column :local_id, ID_TYPES[:local_id], :default => Sequel::LiteralString.new(seq_ref), :null => false
          String :ref
          Integer :ref_num
          String :description
          String :display_name
        end

        @db.create_table_common_extras?(db_rel)
      end

      #Depedency; must be called after create_table_common_fields?
      def create_table_specific_fields?(db_rel)
        cols = db_rel[:columns]
        return nil if cols.nil?
        cols.each{ |col,col_info|
          if fk_rel = col_info[:foreign_key_rel_type]
            other_col_info = col_info.reject{|k,v|k == :foreign_key_rel_type}
            raise Error.new("#{fk_rel} is in foreign key DSL and does not exist") if DB_REL_DEF[fk_rel].nil?
            @db.add_foreign_key? db_rel,col,DB_REL_DEF[fk_rel],other_col_info
          else
            other_col_info = col_info.reject{|k,v|k == :type}
            type = col_info[:type] == :json ? :text : col_info[:type]
            @db.add_column? db_rel,col,type,other_col_info
          end
        }
        nil
      end

      def create_schema_for_db_rel?(db_rel)
        schema = db_rel[:schema]
        return nil if schema.nil?
        return nil if schema == :public
        @db.create_schema?(schema)
      end

     def convert_to_db_rel_form(*arg)
        case arg.size
          when 1
            DBRel[:schema => :public, :table => arg[0]]
          when 2
            DBRel[:schema => arg[0], :table => arg[1]]
        end
      end

      def models 
        classes = [] 
        ObjectSpace.each_object(Module) do |m| 
          classes << m if m.ancestors.include? self and  m != self
        end
        classes 
      end 
  end
end

