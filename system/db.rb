require 'rubygems'
require 'sequel'
require File.expand_path('db/schema_processing', File.dirname(__FILE__))
require File.expand_path('db/data_processing', File.dirname(__FILE__))
require File.expand_path('db/associations', File.dirname(__FILE__))
require File.expand_path('db/infra_tables', File.dirname(__FILE__))

module XYZ
  class DB
    attr_reader :c
    attr_reader :db #TBD: for testing

    def initialize()
      @db = nil
      @c = 2 # TBD for testing hard wiring context
    end

    include SchemaProcessing unless included_modules.include?(SchemaProcessing)
    include DataProcessing unless included_modules.include?(DataProcessing)
    include Associations unless included_modules.include?(Associations)
    include RestURI unless included_modules.include?(RestURI)

    def self.ret_qualified_ref_from_scalars(scalars)
      raise Error if scalars[:ref].nil? 
      scalars[:ref].to_s + (scalars[:ref_num] ? "-" + scalars[:ref_num].to_s : "")
    end

    def self.create(db_params)
      require File.expand_path('db/adapters/' + db_params[:type] , File.dirname(__FILE__))
      db_class = XYZ.const_get db_params[:type].capitalize
      return db_class.new(db_params)
    end

    #TBD: collpase withg related functions in Aux
    def self.ret_json_hash(raw_value) 
      begin
        ret_keys_as_symbols(JSON.parse(raw_value))
      rescue Exception
        #primarily to handle scalars
        raw_value
      end
    end

  private
 
    def self.ret_keys_as_symbols(obj)
      return obj.map{|x|ret_keys_as_symbols(x)} if obj.kind_of?(Array)
      return obj unless obj.kind_of?(Hash)
      ret = {}
      obj.each_pair {|k,v| ret[k.to_sym] = ret_keys_as_symbols(v)}
      ret
    end

    def db_fetch(sql,*args,&block)
      @db.fetch(sql,*args,&block)
    end        

    def db_run(sql,opts={})
      @db.run(sql,opts)
    end        

    def ret_parent_id_field_name(parent_db_rel,db_rel)
      parent_db_rel[:schema] == db_rel[:schema] ?
        (parent_db_rel[:table].to_s + "_id").to_sym :
        (parent_db_rel[:schema].to_s + "_" + parent_db_rel[:table].to_s + "_id").to_sym 
    end
  end

class DBRel < Hash
  def initialize(x)
    super()
    
    if x.kind_of?(Hash)
        x.each_pair{|k,v|self[k.to_sym] = v}
    else
      self[:schema] = :public
      self[:table] = x.to_sym
    end
  end

  def [](x)
    super(x.to_sym)
  end

  def []=(x,y)
    super(x.to_sym,y)
  end

  def schema_table_symbol(table_alias=nil)
    table_no_alias =  self[:schema] == :public ? 
    self[:table] : (self[:schema].to_s +  "__" + self[:table].to_s).to_sym 

    return table_no_alias if table_alias.nil?
      (table_no_alias.to_s + "___" +  table_alias.to_s).to_sym
    end
  end

  TOP_SCHEMA_NAME = :top
  TOP_RELATION_TYPE = :"__top"
  ID_TYPES = {:id => :bigint, :local_id => :integer, :context_id => :integer}
  TOP_LOCAL_ID_SEQ = {:schema => TOP_SCHEMA_NAME, :fn => :local_id_seq}
  ID_INFO_TABLE = DBRel[:schema => TOP_SCHEMA_NAME, :table => :id_info, :id => :relation_id, :local_id => :relation_local_id,:parent_id => :parent_id]
  CLONE_HELPER_TABLE = DBRel[:schema => TOP_SCHEMA_NAME, :table => :clone_helper]
  CONTEXT_TABLE = DBRel[:schema => :context, :table => :context]
  ELEMENT_UPDATE_TRIGGER = {:schema => TOP_SCHEMA_NAME, :fn => :element_update}

  CONTEXT_ID = :c
  FK_CASCADE_OPT = {:on_delete => :cascade, :on_update => :cascade}
  FK_SET_NULL_OPT = {:on_delete => :set_null, :on_update => :set_null}
  DB_REL_DEF = {}
  COMMON_REL_COLUMNS = {}
end

