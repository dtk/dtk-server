module XYZ
  class AttributeLink < Model
    set_relation_name(:attribute,:link)

    class << self
      def up()
        foreign_key :input_id, :attribute, FK_CASCADE_OPT
        foreign_key :output_id, :attribute, FK_CASCADE_OPT
        column :label, :text, :default => "1"
        has_ancestor_field()
        many_to_one :project, :library, :deployment, :component
      end

      ### "Model fns"
      def get_legal_connections(parent_id_handle)
        c = parent_id_handle[:c]
        parent_id = IDInfoTable.get_id_from_id_handle(parent_id_handle)
        where_clause = {:parent_id => parent_id}        
        component_ds = get_objects_just_sequel_dataset(:component,c,where_clause,{:field_set => [:id,:external_cmp_ref]}).from_self(:alias => :component)
        attribute_ds = Model.get_objects_just_sequel_dataset(:attribute,c,nil,{:field_set => [:id,:external_attr_ref,:component_component_id]}).from_self(:alias => :attribute)

        attribute_link_ds = Model.get_objects_just_sequel_dataset(:attribute_link,c).from_self(:alias => :attribute_link)
#     pp component_ds.from_self.join_table(:inner,attribute_ds,{:component_component_id => :id}).all
#      ds= component_ds.graph(attribute_ds,{:component_component_id => :id},{:join_type => :inner}).graph(:attribute__link,{:input_id => :id})
        ds= component_ds.graph(attribute_ds,{:component_component_id => :id},{:join_type => :inner,:table_alias => :attribute}).graph(attribute_link_ds,{:input_id => :id},{:table_alias => :attribute_link}).where({:attribute_link__id => nil})

        puts ds.sql
        ret = Array.new
        raw_result_set = ds.all
        raw_result_set.each do |raw_row|
          row = Hash.new
          [:component,:attribute,:attribute_link].each do |model_name|
            next unless raw_row[model_name]
=begin
TODO Need variant of process_raw_db_row! that for examplek allows omited fields 
            process_raw_db_row!(raw_row[model_name],ModelHandle[:c => c, :model_name => model_name])
=end
            raw_row[model_name].each{|k,v|row["#{model_name}__#{k}"] = v} 
          end
          ret << row unless row.empty?
        end
        ret
=begin
look at wrapping in XYZ::SQL calls that take an ordered list where each element is
one that takes <relation_type>,where,field_set

the other that wraps graph and then applies both "sides" of results through 
          hash = process_raw_scalar_hash!(raw_hash,db_rel,c)
what about?
	  db_rel[:model_class].new(hash,c,relation_type)
=end

      end

      def get_legal_connections_wrt_endpoint(attribute_id_handle,parent_id_handle)
      end
      ##### Actions

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
        link_uris = create_from_hash(factory_id_handle,{link_ref => link_content})
        fn = ret_function_if_can_determine(input_obj,output_obj)
        output_obj.check_and_set_derived_rel_from_link_fn!(fn)
        link_uris
      end

      #returns function if can determine from semantic type of input and output
      #throws an error if finds a mismatch
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

