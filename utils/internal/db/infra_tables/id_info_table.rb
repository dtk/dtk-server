module XYZ
  #TBD: should this class  be in this file or instead somewhere else
  module CommonMixin
    def [](x)
      super(x.to_sym)
    end

    def to_s
      self[:guid] ? "guid=#{self[:guid].to_s}" : "uri=#{self[:uri]}"
    end
   private
    def raise_has_illegal_form(x)
      raise Error.new("#{x.inspect} has incorrect form to be an id handle")
    end
  end

  class IDHandle < Hash
    include CommonMixin

    def get_id()
      (IDInfoTable.get_row_from_id_handle(self,:short_circuit_for_minimal_row => true)||{})[:id]
    end

    def initialize(x)
      super()
      if x[:id_info]
        id_info = x[:id_info]
        if id_info[:c] and id_info[:relation_type] and id_info[:id]
          self[:c] = id_info[:c]
          model_name = id_info[:relation_type]
          self[:guid] = IDInfoTable.ret_guid_from_db_id(id_info[:id],model_name)
          self[:model_name] = model_name
          return freeze
        end
      end

      raise_has_illegal_form(x) unless self[:c] = x[:c]

      if x[:id] and x[:model_name]
        model_name = x[:model_name].to_sym
        self[:guid] = IDInfoTable.ret_guid_from_db_id(x[:id],model_name)
        self[:model_name] = model_name
      elsif x[:guid]
        self[:guid]= x[:guid].to_i
        self[:model_name] = x[:model_name].to_sym if x[:model_name]
      elsif x[:uri]
        self[:uri]= x[:uri]
      else
	raise_has_illegal_form(x) 
      end
      freeze
    end

    def self.[](x)
      new(x)
    end
  end

  class ModelHandle < Hash
    def initialize(c,model_name)
      super()
      self[:c] = c
      self[:model_name] = model_name.to_sym
      freeze
    end
  end

  class IDInfoRow < Hash
    def ret_id_handle()
      IDHandle[CONTEXT_ID => self[CONTEXT_ID], :guid => IDInfoTable::ret_guid_from_id_info(self)]
    end

    def ret_db_id()
      IDInfoTable::db_id_from_guid(IDInfoTable::ret_guid_from_id_info(self))
    end

    def self.[](x)
      new(x)
    end
    def initialize(x)
      super()
      replace(x)
    end
    def [](x)
      super(x.to_sym)
    end

    def ret_qualified_ref()
      self[:ref].to_s + (self[:ref_num] ? "-" + self[:ref_num].to_s : "")
    end
  end

  class IDInfoTable
    class << self
      #TBD: may have parent class for infra tables
      def set_db(db)
        @db = db
      end

      ###### SchemaProcessing
       def create_table?()
	  @db.create_schema?(TOP_SCHEMA_NAME)
	  @db.create_table? ID_INFO_TABLE do
	    String :uri # non null because filled in later
	    foreign_key CONTEXT_ID,  CONTEXT_TABLE.schema_table_symbol, FK_CASCADE_OPT.merge({:null => false,:type => ID_TYPES[:context_id]})
	    String :relation_name
	    column ID_INFO_TABLE[:id], ID_TYPES[:id]
            column ID_INFO_TABLE[:local_id], ID_TYPES[:local_id] 
	    String :relation_type, :size => 25 
	    String :parent_relation_type, :size => 25 
	    String :ref
            Integer :ref_num
	    Boolean :is_factory, :default => false
	    column ID_INFO_TABLE[:parent_id], ID_TYPES[:id], :default => 0
          end
        end
      ###### end: SchemaProcessing

      ###### Initial data
	# TBD: must make so that does not add if there already
	def add_top_factories?()
	  DB_REL_DEF.each{|key,db_info|
	    if db_info[:many_to_one].nil? or db_info[:many_to_one].empty? or 
               (db_info[:many_to_one] ? db_info[:many_to_one] == [db_info[:relation_type]] : nil)
	      uri = "/" + key.to_s
	      context = 2 #TBD : hard wired
	      if get_row_from_uri(uri,context).nil?
	        Log.info("adding to top level factory for: #{key}")
	        insert_factory(key,uri,TOP_RELATION_TYPE.to_s,0,context) 
	      end
	    end
	  }
	end
      ##### end: Initial data

      ###### DataProcessing
        def get_rows_just_dataset(c)
          SQL::Dataset.new(ID_INFO_TABLE[:table],ds().select(CONTEXT_ID,ID_INFO_TABLE[:id],ID_INFO_TABLE[:parent_id],:uri).where(CONTEXT_ID => c))
        end
        def join_condition()
          {:relation_id => :id}
        end
	def get_row_from_id_handle(id_handle,opts={})
          ret = get_minimal_row_from_id_handle(id_handle) if opts[:short_circuit_for_minimal_row]
          return ret if ret
	  c = id_handle[:c]
	  return get_row_from_uri(id_handle[:uri],c,opts) if id_handle[:uri]
	  return get_row_from_guid(id_handle[:guid],opts) if id_handle[:guid]
	  raise Error.new("no uri or guid given") if opts[:raise_error]	
          nil
        end

        def get_row_from_uri(uri,c,opts={})
          ds = ds().where(:uri => uri, CONTEXT_ID => c)
	  if ds.empty? 
	    raise ErrorNotFound.new(:uri,uri) if opts[:raise_error]
	    return nil
	  end
	  unformated_row = ds.first
	  format_row(unformated_row)
        end

        def get_row_from_guid(guid,opts={})
          #NOTE: contingent on id scheme where guid uniquely picks out row
          ds = ds().where(ID_INFO_TABLE[:id] => db_id_from_guid(guid))
	   if ds.empty?
            raise ErrorNotFound.new(:guid,guid) if opts[:raise_error]
            return nil
          end
	  return nil if ds.empty?
	  unformated_row = ds.first
	  format_row(unformated_row)
        end

        def get_id_from_id_handle(id_handle)
          return db_id_from_guid(id_handle[:guid]) if id_handle[:guid]
          r = get_row_from_id_handle(id_handle)
          r ? r[:id] : nil
        end
       
        def update_instance(db_rel,id,uri,relation_type,parent_id_x,parent_relation_type)
	  #  to fill in uri ##TBD: this is split between trigger, which creates it and this code which updates it; may better encapsulate 
	  parent_id = parent_id_x ? parent_id_x : 0
	  rel_qn = @db.fully_qualified_rel_name(db_rel)
	  prt = parent_relation_type.nil? ? TOP_RELATION_TYPE.to_s : parent_relation_type.to_s
	  uri_id = ds().where(ID_INFO_TABLE[:id] => id, :relation_name => rel_qn).
	               update(:uri => uri, :relation_type => relation_type.to_s,
		              :parent_id => parent_id,
			      :parent_relation_type => prt, 
			      :is_factory => false)
	  raise Error.new("error while processing uri table update") if uri_id.nil?
	  uri_id
        end

	def insert_factory(child_type,factory_uri,relation_type,id_x,c)
	  id = id_x ? id_x : 0
	  ds().insert(
	         CONTEXT_ID => c,
	         :uri => factory_uri, 
		 :relation_type => child_type.to_s,
		 :parent_id => id,
		 :parent_relation_type => relation_type.to_s,
		 :is_factory => true)
	  nil
	end
        
        def get_factory_id_handle(parent_id_handle,relation_type)
          parent_uri = parent_id_handle[:uri]
          if parent_uri.nil?
            parent_id_info = get_row_from_id_handle(parent_id_handle)
            return nil if parent_id_info.nil?
            parent_uri = parent_id_info[:uri]
          end

          factory_uri = RestURI.ret_factory_uri(parent_uri,relation_type)
          IDHandle[:c => parent_id_handle[:c], :uri => factory_uri]
        end

	def get_factory_children_rows(factory_id_info)
	  parent_id = factory_id_info[:parent_id]
	  rt = factory_id_info[:relation_type] ? factory_id_info[:relation_type].to_s : nil
	  prt = factory_id_info[:parent_relation_type] ? factory_id_info[:parent_relation_type].to_s : nil
	  c = factory_id_info[CONTEXT_ID]
	  unformated_rows = ds().where(CONTEXT_ID => c, :relation_type => rt, :parent_id => parent_id, :parent_relation_type => prt, :is_factory => false).all
	  unformated_rows.map{|unformated_row|format_row(unformated_row)}
	end

	#### map the db representation of id to guid form
	# currently set so to reflect that a db id is a guid; other possibilities are when guid is id_db_relation + db_id

	def db_id_from_guid(guid)
	  guid.to_i
	end
       public
	def ret_guid_from_id_info(id_info)
	  id_info[:id] 
        end
	def ret_guid_from_db_id(db_id,relation_type)
	  db_id
        end

	def ret_foreign_key_guid(db_id,relation_type)
	  db_id
        end
      #######

       private
        def format_row(unformated_row)
	  IDInfoRow[
	   CONTEXT_ID => unformated_row[CONTEXT_ID],
	   :uri => unformated_row[:uri],
	   :id => unformated_row[ID_INFO_TABLE[:id]],
	   :relation_type => unformated_row[:relation_type] ? unformated_row[:relation_type].to_sym : nil,
	   :parent_relation_type => unformated_row[:parent_relation_type] ? unformated_row[:parent_relation_type].to_sym : nil,
	   :parent_id => unformated_row[:parent_id],
	   :ref => unformated_row[:ref] ? unformated_row[:ref].to_sym : nil,
	   :ref_num => unformated_row[:ref_num],
	   :is_factory => unformated_row[:is_factory],
	   :db_rel => unformated_row[:relation_name].nil? ? nil :   
	     (unformated_row[:relation_name] =~ %r{(.+)\.(.+)}) ? 
	       DBRel[:schema => $1.to_sym, :table => $2.to_sym] : 
	       DBRel[:schema => :public, :table => unformated_row[:relation_name].to_sym]]
        end        
        def get_minimal_row_from_id_handle(id_handle)
          return nil unless id_handle[:model_name] and id_handle[:guid] and id_handle[:c]
          IDInfoRow[CONTEXT_ID => id_handle[:c],:id => db_id_from_guid(id_handle[:guid]),:relation_type => id_handle[:model_name]]
        end
       
	def ds()
	  raise Error.new("db has not been set for #{self.to_s}") if @db.nil?
	  @db.dataset(ID_INFO_TABLE)
        end
    end
  end
end
