#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'sequel'
module DTK
  class DB
    # schema creation methods
    module SchemaProcessing
      def create_table?(db_rel, &block)
        @db.create_table?(db_rel.schema_table_symbol(), &block)
      end

      def create_table(db_rel, &block)
        @db.create_table(db_rel.schema_table_symbol(), &block)
      end

      def table_exists?(db_rel, &block)
        @db.table_exists?(db_rel.schema_table_symbol(), &block)
      end

      # for creating schema
      def create_schema(_schema_name)
         fail Error::NotImplemented.new('create_schema not implemented')
      end

      def schema_exists?(_schema_name)
        fail Error::NotImplemented.new('schema_exists? not implemented')
      end

      def create_schema?(schema_name)
        create_schema(schema_name) unless schema_exists?(schema_name)
  nil
      end

      def add_column(db_rel, *args)
        @db.add_column(db_rel.schema_table_symbol(), *args)
      end

      def modify_column?(db_rel, *args)
        # TODO: this only checks certain things; right now
        # just can modify a varhcar's size
        if args[1] == :varchar
          if args[2].is_a?(Hash) && args[2].key?(:size)
            size = args[2][:size]
            modify_column_varchar_size?(db_rel, args[0], size)
          end
        end
      end

      def add_column?(db_rel, *args)
        if column_exists?(db_rel, args[0])
          modify_column?(db_rel, *args)
        else
          add_column(db_rel, *args)
        end
      end
    end
  end
end