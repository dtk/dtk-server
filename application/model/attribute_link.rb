module XYZ
  class AttributeLink < Model
    set_relation_name(:attribute,:link)

    def self.up()
      foreign_key :input_id, :attribute, FK_CASCADE_OPT
      foreign_key :output_id, :attribute, FK_CASCADE_OPT
      column :label, :text, :default => "1"
      has_ancestor_field()
      many_to_one :library, :datacenter, :component, :project
    end

    #######################
    ### object procssing and access functions
    def self.propagate_over_dir_conn_equality_links(attr_changes)
      #build up pattern that traces from root id_handles in changes pending to directly connected links
      return Array.new if attr_changes.empty?
      attr_mh = attr_changes.first.id_handle.createMH(:model_name => :attribute)

      id_val_pairs = attr_changes.map{|change| {:id => change.id_handle.get_id(),:value_asserted => change.changed_value}}
      input_attr_ds = SQL::ArrayDataset.create(db,id_val_pairs,attr_mh,{:convert_for_update => true})

      #first put in relation that traces along attribute link from output matching an idhandle in changes to inputs
      attr_link_mh = attr_changes.first.id_handle.createMH(:model_name => :attribute_link)
      attr_link_wc = nil
      attr_link_fs = FieldSet.opt([:input_id,:output_id])
      attr_link_ds = get_objects_just_dataset(attr_link_mh,attr_link_wc,attr_link_fs)

      output_attr_mh = attr_link_mh.createMH(:model_name => :attribute)
      #condition is to prune out attributes on output side that have asserted values
      output_attr_wc = {:value_asserted => nil}
      output_attr_fs = FieldSet.opt([:id])
      output_attr_ds = get_objects_just_dataset(output_attr_mh,output_attr_wc,output_attr_fs)

      first_join_ds = input_attr_ds.select({:id => :input_id},{:value_asserted => :value_derived}).from_self.join_table(:inner,attr_link_ds,[:input_id]) 
      attrs_to_change_ds = first_join_ds.join_table(:inner,output_attr_ds,{:id => :output_id})
      update_from_select(output_attr_mh,FieldSet.new([:value_derived]),attrs_to_change_ds)
      nil
    end

    def self.get_legal_connections(parent_id_handle)
      c = parent_id_handle[:c]
      parent_id = IDInfoTable.get_id_from_id_handle(parent_id_handle)
      component_ds = get_objects_just_dataset(ModelHandle.new(c,:component),nil,{:parent_id => parent_id}.merge(FieldSet.opt([:id,:external_ref])))
      attribute_ds = get_objects_just_dataset(ModelHandle.new(c,:attribute),nil,FieldSet.opt([:id,:external_ref,:component_component_id]))

      attribute_link_ds = get_objects_just_dataset(ModelHandle.new(c,:attribute_link))
      component_ds.graph(:inner,attribute_ds,{:component_component_id => :id}).graph(:left_outer,attribute_link_ds,{:input_id => :id}).where({:attribute_link__id => nil}).all
    end

    def self.get_legal_connections_wrt_endpoint(attribute_id_handle,parent_id_handle)
    end

    ##### Actions
=begin TODO: needs fixing up or removal
      def create(target_id_handle,input_id_handle,output_id_handle,href_prefix,opts={})
        raise Error.new("Target location (#{target_id_handle}) does not exist") unless exists? target_id_handle

        input_obj = Object.get_object(input_id_handle)
        raise Error.new("Input endpoint does not exist") if input_obj.nil?
        i_ref = input_obj.get_qualified_ref

        output_obj = Object.get_object(output_id_handle)
        raise Error.new("Output endpoint does not exist") if output_obj.nil?
        o_ref = output_obj.get_qualified_ref

        link_content = {:input_id => input_obj[:id],:output_id => output_obj[:id]}
        link_ref = (i_ref.to_s + "_" + o_ref.to_s).to_sym

        factory_id_handle = get_factory_id_handle(target_id_handle,:attribute_link)
        link_ids = create_from_hash(factory_id_handle,{link_ref => link_content})
        fn = ret_function_if_can_determine(input_obj,output_obj)
        output_obj.check_and_set_derived_rel_from_link_fn!(fn)
        link_ids
      end
=end
      #returns function if can determine from semantic type of input and output
      #throws an error if finds a mismatch
    class << self
      def ret_function_if_can_determine(input_obj,output_obj)
        i_sem = input_obj[:semantic_type]
        return nil if i_sem.nil?
        o_sem = output_obj[:semantic_type]
        return nil if o_sem.nil?

        #TBD: haven't put in any rules if they have different seamntic types
        return nil unless i_sem.keys.first == o_sem.keys.first      
      
        sem_type = i_sem.keys.first
        ret_function_endpoints_same_type(i_sem[sem_type],o_sem[sem_type])
      end

    private

      def ret_function_endpoints_same_type(i,o)
        #TBD: more robust is allowing for example output to be "database", which matches with "postgresql" and also to have version info, etc
        raise Error.new("mismatched input and output types") unless i[:type] == o[:type]
        return :equal if !i[:is_array] and !o[:is_array]
        return :equal if i[:is_array] and o[:is_array]
        return :concat if !i[:is_array] and o[:is_array]
        raise Error.new("mismatched input and output types") if i[:is_array] and !o[:is_array]
        nil
      end
    end

    ##instance fns
    def get_input_attribute(opts={})
      return nil if self[:input_id].nil?
      get_object_from_db_id(self[:input_id],:attribute)
    end

    def get_output_attribute(opts={})
      return nil if self[:output_id].nil?
      get_object_from_db_id(self[:output_id],:attribute)
    end
  end
  # END Attribute class definition
end

