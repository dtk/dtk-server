require 'sequel'
module DTK
  class DB
    # schema creation methods
    module SchemaProcessing

      def create_table?(db_rel,&block)
        @db.create_table?(db_rel.schema_table_symbol(),&block)
      end
      def create_table(db_rel,&block)
        @db.create_table(db_rel.schema_table_symbol(),&block)
      end
      def table_exists?(db_rel,&block)
        @db.table_exists?(db_rel.schema_table_symbol(),&block)
      end

      # for creating schema
      def create_schema(schema_name)
         raise Error::NotImplemented.new("create_schema not implemented")
      end
      def schema_exists?(schema_name)
        raise Error::NotImplemented.new("schema_exists? not implemented")
      end
      def create_schema?(schema_name)
        create_schema(schema_name) if !schema_exists?(schema_name)
	nil        
      end

      def add_column(db_rel,*args)
        @db.add_column(db_rel.schema_table_symbol(),*args)
      end

      def modify_column?(db_rel,*args)
        #TODO: this only checks certain things; right now
        #just can modify a varhcar's size
        if args[1] == :varchar 
          if size = args[2].kind_of?(Hash) && args[2][:size]
            modify_column_varchar_size?(db_rel,args[0],size)
          end
        end
      end

      def add_column?(db_rel,*args)
        if column_exists?(db_rel,args[0])
          modify_column?(db_rel,*args)
        else
          add_column(db_rel,*args) 
        end
      end
    end
  end
end

