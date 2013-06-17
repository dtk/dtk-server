require 'sequel'
require 'singleton'
require 'pp'
module DTKMigration
  #this does an insert and also updates appropriately the top.id_info table
  def self.insert(schema,table,row)
    sequel_db(schema,table).insert(row) do |db_ret|
      pp db_ret
    end
  end

  def self.db_rebuild(*model_names)
    DTKModel.instance.db_rebuild(model_names)
  end
 private
  class DTKModel
    include Singleton
    def initialize()
      require File.expand_path('../app_migration', File.dirname(__FILE__))
    end
    def db_rebuild(model_names)
      ::DTK::Model.db_rebuild(DBinstance,model_names,::DTK::Opts.new(:raise_error => true))
    end
  end
  
  def self.sequel_db(schema,table)
    ::Sequel::DB["#{schema}__#{table}".to_sym]
  end
end
