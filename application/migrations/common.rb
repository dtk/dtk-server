require 'sequel'
require 'pp'
module DTK
  class Migration
    #this does an insert and also updates appropriately the top.id_info table
    def self.insert(schema,table,row)
      sequel_db(schema,table).insert(row) do |db_ret|
        pp db_ret
      end
    end
  private
    def self.sequel_db(schema,table)
      ::Sequel::DB["#{schema}__#{table}".to_sym]
    end
  end
end
