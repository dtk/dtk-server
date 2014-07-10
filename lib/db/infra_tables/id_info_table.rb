# TODO: unify relation_type and model_name
module XYZ

  # TODO: should this class  be in this file or instead somewhere else
  module CommonMixin
    def [](x)
      super(x.to_sym)
    end

    # used when first creating without id (i.e. created before saving)
    def create_stubIDH()
      args = {:model_name => self[:model_name], :c => self[:c]}
      args.merge!(:group_id => self[:group_id]) if self[:group_id]
      IDHandle.new(args,:no_id => true)
    end

    def createIDH(x)
      args = x
      if x[:uri]
        each{|k,v|args[k] ||= v unless k == :guid}
      elsif x[:id] or x[:guid]
        each{|k,v|args[k] ||= v unless k == :uri}
      else
        args = self.merge(x)
      end
      IDHandle.new(args)
    end

    def create_top()
      IDHandle.new(reject{|k,v|[:uri,:guid].include?(k)}.merge(:uri => "/"))
    end

    # has form hash or if just symbol then its the attribute :model_name
    def createMH(x={})
      x = {:model_name => x} if x.kind_of?(Symbol)
      vals = [:c,:model_name,:parent_model_name].inject({}){|h,k|h.merge({k => self[k]})}
      vals.merge!(x)
      vals[:parent_model_name] ||= get_parent_model_name()
      vals[:model_name] ||= get_model_name()
      user_info = {:group_id => self[:group_id]||vals[:group_id]}
      ModelHandle.new(vals[:c],vals[:model_name],vals[:parent_model_name],user_info)
    end

    def create_childMH(child_model_name)
      user_info = {:group_id => self[:group_id]}
      ModelHandle.new(self[:c],child_model_name,self[:model_name],user_info)
    end

    def create_peerMH(model_name)
      user_info = {:group_id => self[:group_id]}
      ModelHandle.new(self[:c],model_name,self[:parent_model_name],user_info)
    end

    def get_children_model_handles(opts={})
      get_children_model_names(opts).map do |child_model_name|
        user_info = {:group_id => self[:group_id]}
        ModelHandle.new(self[:c],child_model_name,self[:model_name],user_info)
      end
    end

    def db()
      Model.model_class(self[:model_name]).db
    end

    def to_s
      model_name = "model_name=#{self[:model_name]||"UNKNOWN"}"
      uri_or_guid = 
        if kind_of?(IDHandle)
          self[:guid] ? "; guid=#{self[:guid].to_s}" : "; uri=#{self[:uri]}"
        else
          ""
        end
      parent_model_name =  self[:parent_model_name] ? "; parent_model_name = #{self[:parent_model_name]}" : ""
      "#{model_name}#{uri_or_guid}#{parent_model_name}"
    end

   private
    def get_children_model_names(opts={})
      ret = db_rel[:one_to_many]||[]
      ret = ret - (db_rel[:one_to_many_clone_omit]||[]) if opts[:clone_context]
      ret
    end
    def db_rel()
      DB_REL_DEF[self[:model_name]]
    end
    def raise_has_illegal_form(x)
      raise Error.new("#{x.inspect} has incorrect form to be an id handle")
    end
  end

  class IDHandle < Hash
    include CommonMixin

    def create_object(opts={})
      model_name =
        if opts[:model_name]
          opts[:model_name]
        elsif not opts[:donot_find_subtype]
          Model.find_subtype_model_name(self,opts)
        else
          self[:model_name]
        end
      Model.model_class(model_name).new({:id => get_id()},self[:c],nil,self)
    end

    def get_field?(field)
      create_object().get_field?(field)
    end

    def i18n_language()
      # TODO: stub
       R8::Config[:default_language]
    end

    def get_objects_from_sp_hash(sp_hash,opts={})
      create_object().get_objects_from_sp_hash(sp_hash,opts)
    end

    def get_id()
      (IDInfoTable.get_row_from_id_handle(self,:short_circuit_for_minimal_row => true)||{})[:id]
    end

    def get_uri()
      self[:uri] || IDInfoTable.get_row_from_id_handle(self)[:uri]
    end

    def get_child_id_handle(child_relation_type,qualified_child_ref)
      factory_uri = RestURI.ret_factory_uri(get_uri(),child_relation_type)
      child_uri = RestURI.ret_child_uri_from_qualified_ref(factory_uri,qualified_child_ref)
      createIDH(:model_name => child_relation_type,:uri => child_uri)
    end

    def get_parent_id_handle()
      # TODO: short circuit if parent_guid and parent_model_name are set
      c = self[:c]
      id_info = IDInfoTable.get_row_from_id_handle(self)
      return nil unless id_info and id_info[:parent_relation_type] and id_info[:parent_id] 
      IDHandle[:c => c, :id => id_info[:parent_id], :model_name => id_info[:parent_relation_type]]
    end
    def get_parent_id_handle_with_auth_info()
      idh = get_parent_id_handle()
      obj = idh.create_object().update_object!(:group_id)
      idh.createIDH(:group_id => obj[:group_id])
    end
    def get_parent_id_handle_with_display_name()
      idh = get_parent_id_handle()
      idh.createIDH(:display_name =>  Model.get_display_name(idh))
    end

    # returns nil if model_name given and top does not mactch it
    def get_top_container_id_handle(model_name=nil,opts={})
      model_name = :datacenter if model_name==:target #TODO: with change to Model.matching_models? in place of == may not need this
      return self if model_name and Model.matching_models?(model_name,self[:model_name])
      uri = get_uri()
      top_model_name = RestURI.ret_top_container_relation_type(uri)
      return nil if model_name and not Model.matching_models?(model_name,top_model_name)
      c = self[:c]
      top_container_uri = RestURI.ret_top_container_uri(uri)
      hash_info = {:c => c, :model_name => top_model_name, :uri => top_container_uri}
      if opts[:auth_info_from_self]
        hash_info.merge!(:group_id => self[:group_id]) if self[:group_id]
      end
      IDHandle[hash_info]
    end

    def get_parent_id_info()
      parent_id_handle = get_parent_id_handle()
      IDInfoTable.get_row_from_id_handle parent_id_handle
    end

    def is_top?()
      self[:uri] == "/"
    end

    def initialize(x,opts={})
      super()
      # TODO: cleanup to take into account of this can be factory and whether enforce this must has model_name and parent_model_nmae
      if x[:id_info]
        id_info = x[:id_info]
        if id_info[:c] and id_info[:relation_type] and id_info[:id]
          self[:c] = id_info[:c]
          model_name = id_info[:relation_type]
          self[:guid] = IDInfoTable.ret_guid_from_db_id(id_info[:id],model_name)
          self[:model_name] = model_name
          self[:parent_model_name] = get_parent_id_handle()[:model_name] if opts[:set_parent_model_name]
          return 
        end
      end

      raise_has_illegal_form(x) unless self[:c] = x[:c]
      if opts[:no_id]
        raise_has_illegal_form(x) unless self[:model_name] = x[:model_name] && x[:model_name].to_sym
        self[:group_id] = x[:group_id] if x[:group_id]
        return
      end

      if x[:id] and x[:model_name]
        model_name = x[:model_name].to_sym
        self[:guid] = IDInfoTable.ret_guid_from_db_id(x[:id],model_name)
      elsif x[:guid]
        self[:guid]= x[:guid].to_i
      elsif x[:uri]
        self[:uri]= x[:uri]
        unless x[:model_name]
          # TODO: cleanup; probably removing id_handle staht can be factory ids
          unless x[:is_factory]
            self[:model_name] = RestURI.ret_relation_type_from_instance_uri(x[:uri])
          end
        end
      else
	raise_has_illegal_form(x) 
      end
      self[:model_name] = x[:model_name].to_sym if x[:model_name]
      self[:display_name] = x[:display_name] if x[:display_name]
      self[:parent_guid] = x[:parent_guid].to_i if x[:parent_guid]
      self[:parent_model_name] = x[:parent_model_name].to_sym if x[:parent_model_name]
      self[:user_id] = x[:user_id] if x[:user_id]
      self[:group_id] = x[:group_id] if x[:group_id]
      if opts[:set_parent_model_name]
        unless self[:parent_model_name]
          parent_idh = get_parent_id_handle()
          if parent_idh
            self[:parent_model_name] = parent_idh[:model_name] 
          else
           # TODO: commented out beacuse noisy error
            # Log.error("cannot find parent info from #{self.inspect}")
          end
        end
      end
      # TODO: removed freeze
    end

    def self.[](x)
      new(x)
    end
   private
    def get_parent_model_name()
      self[:parent_model_name] || (get_parent_id_handle()||{})[:model_name]
    end

    def get_model_name()
      self[:model_name] || (IDInfoTable.get_row_from_id_handle(self)||{})[:relation_type]
    end
  end

  class ModelHandle < Hash
    include CommonMixin
    def initialize(c,model_name,parent_model_name=nil,user=nil)
      super()
      self[:c] = c
      self[:model_name] = model_name.to_sym
      self[:parent_model_name] = parent_model_name.to_sym if parent_model_name
      if user
        self[:user_id] = user[:id] if  user[:id]
        self[:group_id] =  user[:group_id] if user[:group_id]
      end
      # TODO: removed freeze
    end

    def self.create_from_user(user,model_name)
      parent_model_name=nil
      self.new(user[:c],model_name,parent_model_name,user)
    end

    def create_object_from_hash(hash,opts={})
      unless hash[:id]
        raise Error.new("hash must contain:id key")
      end
      idh = createIDH(:id => hash[:id])
      model_name =
       if not opts[:donot_find_subtype]
         Model.find_subtype_model_name(idh,opts)
       else
         self[:model_name]
       end
      Model.model_class(model_name).new(hash,self[:c],nil,idh)
    end

    def get_virtual_columns()
      DB_REL_DEF[self[:model_name]][:virtual_columns]
    end

    def get_columns()
      DB_REL_DEF[self[:model_name]][:columns]
    end

    # TODO: refactor this, DB.parent_field, and DB.ret_parent_id_field_name and reroot all calls to this fn and variant that takes parent_model_name as arg
    def parent_id_field_name(parent_model_name_or_idh=nil)
      arg = parent_model_name_or_idh #shorthand
      parent_model_name ||= self[:parent_model_name]||(arg && (arg.kind_of?(Symbol) ? arg : arg[:model_name]))
      return nil unless parent_model_name
      DB.parent_field(parent_model_name,self[:model_name])
    end
   private
    def get_parent_model_name()
      self[:parent_model_name]
    end
  end

  class IDInfoRow < Hash
    def ret_id_handle()
      IDHandle[CONTEXT_ID => self[CONTEXT_ID], :guid => IDInfoTable::ret_guid_from_id_info(self), :model_name => self[:relation_type]]
    end

    # TOTO rename to ret_id()
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
      # TODO: may have parent class for infra tables
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
	    String :relation_type, :size => 50 
	    String :parent_relation_type, :size => 50 
	    String :ref
            Integer :ref_num
	    Boolean :is_factory, :default => false
	    column ID_INFO_TABLE[:parent_id], ID_TYPES[:id], :default => 0
          end
        end
      ###### end: SchemaProcessing

      ###### Initial data
	# TODO: must make so that does not add if there already
	def add_top_factories?()
	  DB_REL_DEF.each{|key,db_info|
	    if db_info[:many_to_one].nil? or db_info[:many_to_one].empty? or 
               (db_info[:many_to_one] ? db_info[:many_to_one] == [db_info[:relation_type]] : nil)
	      uri = "/" + key.to_s
	      context = 2 #TODO : hard wired
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
            if opts[:create_factory_if_needed] # should only be applied for factory uri
              return create_factory(uri,c,:raise_error => true) #not doing recursive create
            end
	    raise Error::NotFound.new(:uri,uri) if opts[:raise_error]
	    return nil
	  end
	  unformated_row = ds.first
	  format_row(unformated_row)
        end

        def create_factory(factory_uri,c,opts={})
          relation_type,parent_uri = RestURI.parse_factory_uri(factory_uri)
          par_id_info = get_row_from_uri(parent_uri,c,opts)
          if par_id_info
            insert_factory(relation_type,factory_uri,par_id_info[:relation_type],par_id_info[:id],c)
            # TODO: more effiienct would be if insert_factory returns new row
            get_row_from_uri(factory_uri,c,:raise_error => true)
          end
        end
        private :create_factory



        def get_row_from_guid(guid,opts={})
          # NOTE: contingent on id scheme where guid uniquely picks out row
          ds = ds().where(ID_INFO_TABLE[:id] => db_id_from_guid(guid))
	   if ds.empty?
            raise Error::NotFound.new(:guid,guid) if opts[:raise_error]
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

        def update_instances(model_handle,returning_cols)
          return nil if returning_cols.empty?
          sample_parent_id = returning_cols.first[:parent_id]
          return update_top_instances(model_handle,returning_cols) if sample_parent_id.nil? or sample_parent_id == 0
          pairs_ds =  SQL::ArrayDataset.create(@db,returning_cols.map{|y|{:pair_id => y[:id], :pair_parent_id => y[:parent_id]||0}},ModelHandle.new(model_handle[:c],:pairs)).sequel_ds
          parent_ds_wo_alias =  ds().select(:relation_id.as(:prt_relation_id),:relation_type.as(:prt_relation_type), :uri.as(:prt_uri))
          parent_ds = SQL::aliased_expression(parent_ds_wo_alias,:parents)

          update_ds = ds_with_from(parent_ds).join(pairs_ds,{:pair_parent_id => :parents__prt_relation_id}).where({:pair_id => :relation_id})

          uri = SQL::ColRef.concat{|o|[:prt_uri,"/#{model_handle[:model_name]}/",:ref,o.case{[[{:ref_num=> nil},""],o.concat("-",:ref_num)]}]}
          update_ds.update({
             :uri => uri,
             :relation_type => model_handle[:model_name].to_s,
             :parent_id => :pair_parent_id, 
             :parent_relation_type => :prt_relation_type})
        end

        def update_top_instances(model_handle,returning_cols)
          update_ds = ds().where(:relation_id => returning_cols.map{|r|r[:id]})
          uri = SQL::ColRef.concat{|o|["/#{model_handle[:model_name]}/",:ref,o.case{[[{:ref_num=> nil},""],o.concat("-",:ref_num)]}]}
          update_ds.update({:uri => uri,:relation_type => model_handle[:model_name].to_s})

        end
       # TODO: see if bug below to set :parent_relation_type when parent_relation_type.nil?, but not above
        def update_instance(db_rel,id,uri,relation_type,parent_id_x,parent_relation_type)
	  #  to fill in uri ##TODO: this is split between trigger, which creates it and this code which updates it; may better encapsulate 
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
          IDHandle[:c => parent_id_handle[:c], :uri => factory_uri, :is_factory => true]
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

        def get_id_handles_matching_uris(parent_idh,fully_qual_uris)
          unformated_rows = ds().where(CONTEXT_ID => parent_idh[CONTEXT_ID], :uri => fully_qual_uris, :is_factory=>false).all()
          unformated_rows.map do |r|
            mh = parent_idh.create_childMH(r[:relation_type].to_sym)
            mh.createIDH(:id => r[:relation_id])
          end
        end

        def get_ndx_ids_matching_relative_uris(parent_idh,parent_uri,child_relative_uris)
          ndx_uris = child_relative_uris.inject(Hash.new) do |h,child_uri|
            uri = RestURI.ret_child_uri_from_qualified_ref(parent_uri,child_uri)
            h.merge(uri => child_uri)
          end
	  unformated_rows = ds().where(CONTEXT_ID => parent_idh[CONTEXT_ID], :uri => ndx_uris.keys, :is_factory=>false).all()
          unformated_rows.inject(Hash.new){|h,r|h.merge(ndx_uris[r[:uri]] => r[:relation_id])}
        end

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
          @db.dataset(ID_INFO_TABLE)
        end
	def ds_with_from(*from_clauses)
          @db.dataset(ID_INFO_TABLE,nil,*from_clauses)
        end
      end
    end
end
