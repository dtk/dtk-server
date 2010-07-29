
require 'sequel'

module XYZ
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
         raise ErrorNotImplemented.new("create_schema not implemented")
      end
      def schema_exists?(schema_name)
        raise ErrorNotImplemented.new("schema_exists? not implemented")
      end
      def create_schema?(schema_name)
        create_schema(schema_name) if !schema_exists?(schema_name)
	nil        
      end

      def add_column(db_rel,*args)
        @db.add_column(db_rel.schema_table_symbol(),*args)
      end
      def add_column?(db_rel,*args)
        add_column(db_rel,*args) if ! column_exists?(db_rel,args[0])
      end
    end
  end
end

