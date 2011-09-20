module XYZ
  class AttributeLink < Model
    ##########################  add new links ##################
    def self.create_attribute_links(parent_idh,rows_to_create,opts={})
      return Array.new if rows_to_create.empty?
      attr_mh = parent_idh.createMH(:attribute)
      attr_link_mh = parent_idh.create_childMH(:attribute_link)

      attr_info = get_attribute_info(attr_mh,rows_to_create)
      add_link_fns!(rows_to_create,attr_info)

      #add parent_col and ref
      parent_col = attr_link_mh.parent_id_field_name()
      parent_id = parent_idh.get_id()
      rows_to_create.each do |row|
        row[parent_col] ||= parent_id
        row[:ref] ||= "attribute_link:#{row[:input_id]}-#{row[:output_id]}"
      end

      rows_for_array_ds = rows_to_create.map{|row|Aux::hash_subset(row,row.keys - remove_keys)}
      select_ds = SQL::ArrayDataset.create(db,rows_for_array_ds,attr_link_mh,:convert_for_create => true)
      override_attrs = {}
      field_set = FieldSet.new(model_name,rows_for_array_ds.first.keys)
      returning_ids = create_from_select(attr_link_mh,field_set,select_ds,override_attrs,:returning_sql_cols=> [:id])
      #insert the new ids into rows_to_create
      returning_ids.each_with_index{|id_info,i|rows_to_create[i][:id] = id_info[:id]}

      propagate_from_create(attr_mh,attr_info,rows_to_create)
    end

   private
    #mechanism to compensate for fact that cols arer being added by processing fns to rows_to_create that
    #must be removed before they are saved
    RemoveKeys = Array.new
    def self.remove_keys()
      RemoveKeys
    end
    def self.add_to_remove_keys(*keys)
      keys.each{|k|RemoveKeys << k unless RemoveKeys.include?(k)}
    end

    def self.get_attribute_info(attr_mh,rows_to_create)
      endpoint_ids = rows_to_create.map{|r|[r[:input_id],r[:output_id]]}.flatten.uniq
      sp_hash = {
        :columns => [:id,:attribute_value,:semantic_type_object,:component_parent],
        :filter => [:oneof, :id, endpoint_ids]
      }
      attr_rows = get_objs(attr_mh,sp_hash)
      attr_rows.inject({}){|h,attr|h.merge(attr[:id] => attr)}
    end

    def self.check_constraints(attr_mh,rows_to_create)
      #TODO: may modify to get all constraints from  conn_info_list
      rows_to_create.each do |row| 
        #TODO: right now constraints just on input, not output, attributes
        attr = attr_mh.createIDH(:id => row[:input_id]).create_object()
        constraints = Constraints.new()
        if row[:link_defs]
          unless row[:conn_info]
           constraints << Constraint::Macro.no_legal_endpoints(row[:link_defs])
          end
        end
        next if constraints.empty?
        target = {:target_port_id_handle => attr_mh.createIDH(:id => row[:output_id])}
        #TODO: may treat differently if rows_to_create has multiple rows
        constraints.evaluate_given_target(target, :raise_error_when_error_violation => true)
      end
    end

    def self.add_link_fns!(rows_to_create,attr_info)
      rows_to_create.each do |row|
        input_attr = attr_info[row[:input_id]].merge(row[:input_path] ? {:input_path => row[:input_path]} : {})
        output_attr = attr_info[row[:output_id]].merge(row[:output_path] ? {:output_path => row[:output_path]} : {})
        row[:function] = SemanticType.find_link_function(input_attr,output_attr)
      end
    end
    add_to_remove_keys :input_path,:output_path


####################
   public
    ### special purpose create links ###
    def self.create_links_node_group_members(node_group_id_handle,ng_cmp_id_handle,node_cmp_id_handles)
      node_cmp_mh = node_cmp_id_handles.first.createMH
      node_cmp_wc = {:ancestor_id => ng_cmp_id_handle.get_id()}
      node_cmp_fs = FieldSet.opt([:id],:component)
      node_cmp_ds = get_objects_just_dataset(node_cmp_mh,node_cmp_wc,node_cmp_fs)

      attr_mh = node_cmp_mh.create_childMH(:attribute)

      attr_parent_col = attr_mh.parent_id_field_name()
      node_attr_fs = FieldSet.opt([attr_parent_col,:id,:ref],:attribute)
      node_attr_ds = get_objects_just_dataset(attr_mh,nil,node_attr_fs)

      group_attr_wc = {attr_parent_col => ng_cmp_id_handle.get_id()}
      group_attr_fs = FieldSet.opt([:id,:ref],:attribute)
      group_attr_ds = get_objects_just_dataset(attr_mh,group_attr_wc,group_attr_fs)

      #attribute link has same parent as node_group
      attr_link_mh = node_group_id_handle.create_peerMH(:attribute_link)
      attr_link_parent_id_handle = node_group_id_handle.get_parent_id_handle()
      attr_link_parent_col = attr_link_mh.parent_id_field_name()
      ref_prefix = "attribute_link:"
      i1_ds = node_cmp_ds.select(
         {SQL::ColRef.concat(ref_prefix,:input__id.cast(:text),"-",:output__id.cast(:text)) => :ref},
         {attr_link_parent_id_handle.get_id() => attr_link_parent_col},
         {:input__id => :input_id},
         {:output__id => :output_id},
         {"member" => :type},                                 
         {"eq" => :function})
      first_join_ds = i1_ds.join_table(:inner,node_attr_ds,{attr_parent_col => :id},{:table_alias => :input})
      attr_link_ds = first_join_ds.join_table(:inner,group_attr_ds,[:ref],{:table_alias => :output})

      attr_link_fs = FieldSet.new(:attribute,[:ref,attr_link_parent_col,:input_id,:output_id,:function,:type])
      override_attrs = {}
            
      opts = {:duplicate_refs => :no_check,:returning_sql_cols => [:input_id,:output_id]} 
      create_from_select(attr_link_mh,attr_link_fs,attr_link_ds,override_attrs,opts)
    end


    def self.create_links_sap(link_info,sap_attr_idh,sap_config_attr_idh,par_idh,node_idh)
      attr_link_mh = sap_attr_idh.createMH(:model_name => :attribute_link, :parent_model_name => :node)
      sap_id,sap_config_id,par_id,node_id = [sap_attr_idh,sap_config_attr_idh,par_idh,node_idh].map{|x|x.get_id()}

      sap_config_name = link_info[:sap_config]
      sap_name = link_info[:sap]
      parent_attr_name = link_info[:parent_attr_name]

      new_link_rows =
        [
         {
           :ref => "#{sap_config_name}:#{sap_config_id.to_s}-#{sap_id}",
           :display_name => "link:#{sap_config_name}-#{sap_name}",
           :input_id => sap_id,
           :output_id => sap_config_id,
           :type => "internal",
           :hidden => true,
           :function => link_info[:sap_config_fn_name],
           :node_node_id => node_id
         },
         {
           :ref => "#{parent_attr_name}:#{par_id.to_s}-#{sap_id}",
           :display_name => "link:#{parent_attr_name}-#{sap_name}",
           :input_id => sap_id,
           :output_id => par_id,
           :type => "internal",
           :hidden => true,
           :function => link_info[:parent_fn_name],
           :node_node_id => node_id
         }
        ]
      create_from_rows(attr_link_mh,new_link_rows)
    end

    #TODO: deprecate below after subsuming from above
    def self.create_links_l4_sap(new_sap_attr_idh,sap_config_attr_idh,ipv4_host_addrs_idh,node_idh)
      attr_link_mh = node_idh.createMH(:model_name => :attribute_link, :parent_model_name => :node)
      new_sap_id,sap_config_id,ipv4_id,node_id = [new_sap_attr_idh,sap_config_attr_idh,ipv4_host_addrs_idh,node_idh].map{|x|x.get_id()}
      
      new_link_rows =
        [
         {
           :ref => "sap_config:#{sap_config_id.to_s}-#{new_sap_id}",
           :display_name => "link:sap_config-sap",
           :input_id => new_sap_id,
           :output_id => sap_config_id,
           :type => "internal",
           :hidden => true,
           :function => "sap_config__l4",
           :node_node_id => node_id
         },
         {
           :ref => "host_address:#{ipv4_id.to_s}-#{new_sap_id}",
           :display_name => "link:host_address-sap",
           :input_id => new_sap_id,
           :output_id => ipv4_id,
           :type => "internal",
           :hidden => true,
           :function => "host_address_ipv4",
           :node_node_id => node_id
         }
        ]
      create_from_rows(attr_link_mh,new_link_rows)
    end

     ### aux fn for create links ###
    def self.propagate_from_create(attr_mh,attr_info,attr_link_rows)
      new_val_rows = attr_link_rows.map do |attr_link_row|
        input_attr = attr_info[attr_link_row[:input_id]]
        output_attr = attr_info[attr_link_row[:output_id]]
        propagate_proc = PropagateProcessor.new(attr_link_row,input_attr,output_attr)
        propagate_proc.propagate().merge(:id => input_attr[:id])
      end
      return Array.new if new_val_rows.empty?
      Attribute.update_attribute_values(attr_mh,new_val_rows,[:value_derived])
    end


    ########################## end add new links ##################

    ########################## propagate changes ##################
    #returns all changes
    #TODO: flat list now; look at nested list reflecting hierarchical plan decomposition
    #TODO: rather than needing look up existing values for output vars; might allow change/new values to be provided as function arguments
   def self.propagate(output_attr_id_handles,parent_id_handles=nil)
      return Hash.new if output_attr_id_handles.empty?
      attr_mh = output_attr_id_handles.first.createMH()
      output_attr_ids = output_attr_id_handles.map{|idh|idh.get_id()}
      sp_hash = {
        :relation => :attribute,
        :filter => [:and,[:oneof, :id, output_attr_ids]],
        :columns => [:id,:value_asserted,:value_derived,:semantic_type,:linked_attributes]
      }
      attrs_to_update = Model.get_objects_from_sp_hash(attr_mh,sp_hash)
    
      #dont propagate to attributes with asserted values TODO: push this restriction into search pattern
      attrs_to_update.reject!{|r|(r[:input_attribute]||{})[:value_asserted]}
      change_info = Hash.new
      new_val_rows = Array.new

      
      parent_map = Hash.new
      if parent_id_handles
        output_attr_ids.each_with_index{|id,i|parent_map[id] = parent_id_handles[i]}
      end

      attrs_to_update.each_with_index do |row,i|
        input_attr_row = row[:input_attribute]
        output_attr_row = row
        propagate_proc = PropagateProcessor.new(row[:attribute_link],input_attr_row,output_attr_row)

        new_value_row = propagate_proc.propagate().merge(:id => input_attr_row[:id])

        new_val_rows << new_value_row

        change = {
          :new_item => attr_mh.createIDH(:guid => input_attr_row[:id], :display_name => input_attr_row[:display_name]),
          :change => {:old => input_attr_row[:value_derived], :new => new_value_row[:value_derived]}
        }
        change.merge!(:parent => parent_map[row[:id]]) if parent_map[row[:id]]
        change_info[input_attr_row[:id]] = change
      end

      return Hash.new if new_val_rows.empty?
      opts = {:update_only_if_change => [:value_derived],:returning_cols => [:id]}
      changed_ids = Attribute.update_attribute_values(attr_mh,new_val_rows,:value_derived,opts)
      #if no changes exit, otherwise recursively call propagate
      return Hash.new if changed_ids.empty?

      #TODO: using flat structure wrt to parents; so if parents pushed down use parents associated with trigger for change
      pruned_changes = Hash.new
      nested_parent_idhs = nil
      nested_idhs = Array.new
      changed_ids.each do |r|
        id = r[:id]
        pruned_changes[id] = change_info[id]
        nested_idhs << attr_mh.createIDH(:id => id)
        if parent_idh = change_info[id][:parent]
          nested_parent_idhs ||= Array.new
          nested_parent_idhs << parent_idh
        end
      end
      
      propagated_changes = propagate(nested_idhs,nested_parent_idhs)
      pruned_changes.merge(propagated_changes)
    end

   ########################## end: propagate changes ##################
    class IndexMap < Array
      def merge_into(source,output_var)
        self.inject(source) do |ret,el|
          delta = el[:output].take_slice(output_var)
          el[:input].merge_into(ret,delta)
        end
      end

      def self.convert_if_needed(x)
        x.kind_of?(Array) ? create_from_array(x) : x
      end
      
      def self.generate_from_paths(input_path,output_path)
        create_from_array([{:input => input_path, :output => output_path}])
      end

      def self.generate_from_bounds(lower_bound,upper_bound,offset)
        create_from_array((lower_bound..upper_bound).map{|i|{:output => [i], :input => [i+offset]}})
      end

      def input_array_indexes()
        ret = Array.new
        self.map do |el|
          raise Error.new("unexpected form in input_array_indexes") unless el[:input].is_singleton_array?()
          el[:input].first
        end 
      end

      def self.resolve_input_paths!(index_map_list,component_mh)
        return if index_map_list.empty?
        paths = Array.new
        index_map_list.each{|im|im.each{|im_el|paths << im_el[:input]}}
        IndexMapPath.resolve_paths!(paths,component_mh)
      end

     private
      def self.create_from_array(a)
        return nil unless a
        ret = new()
        a.each do |el| 
          input = el[:input].kind_of?(IndexMapPath) ? el[:input] : IndexMapPath.create_from_array(el[:input])
          output = el[:output].kind_of?(IndexMapPath) ? el[:output] : IndexMapPath.create_from_array(el[:output])
          ret << {:input => input, :output => output}
        end
        ret
      end
    end

    class IndexMapPath < Array
      def is_singleton_array?()
        self.size == 1 and is_array_el?(self.first)
      end
      def take_slice(source)
        return source if self.empty?
        return nil if source.nil?
        el = self.first
        if is_array_el?(el)
          if source.kind_of?(Array)
            rest().take_slice(source[el])
          else
            Log.error("array expected")
            nil
          end
        else
          if source.kind_of?(Hash)
            rest().take_slice(source[el.to_s])
          else
            Log.error("hash expected")
            nil
          end
        end
      end

      def merge_into(source,delta)
        return delta if self.empty?
        el = self.first
        if is_array_el?(el)
          if source.kind_of?(Array) or source.nil?()
            ret = source ? source.dup : []
            if ret.size <= el
              ret += (0.. el - ret.size).map{nil}
            end
            ret[el] = rest().merge_into(ret[el],delta)
            ret
          else
            Log.error("array expected")
            nil
          end
        else
          if source.kind_of?(Hash) or source.nil?()
            ret = source || {}
            ret.merge(el.to_s => rest().merge_into(ret[el.to_s],delta))
          else
            Log.error("hash expected")
            nil
          end
        end
      end

      #TODO: more efficient and not needed if can be resolved when get index
      def self.resolve_paths!(path_list,component_mh)
        ndx_cmp_idhs = Hash.new
        path_list.each do |index_map_path|
          index_map_path.each_with_index do |el,i|
            next unless el.kind_of?(Hash)
            next unless id = (el[:create_component_index]||{})[:component_id] 
            ndx_cmp_idhs[id] ||= {:idh => component_mh.createIDH(:id => id), :elements => Array.new}
            ndx_cmp_idhs[id][:elements] << {:path => index_map_path, :i => i}
          end
        end
        return if ndx_cmp_idhs.empty?
        cmp_idhs =  ndx_cmp_idhs.values.map{|x|x[:idh]}
        sp_hash = {:columns => [:id,:multiple_instance_ref]}
        opts = {:keep_ref_cols => true}
        cmp_info = Model.get_objects_in_set_from_sp_hash(cmp_idhs,sp_hash,opts)
        cmp_info.each do |r|
          ref = r[:multiple_instance_ref]
          ndx_cmp_idhs[r[:id]][:elements].each do |el|
            el[:path][el[:i]] = ref
          end
        end
      end
     private
      def self.create_from_array(a)
        ret = new()
        return ret unless a
        a.each do |el| 
          if el.kind_of?(String) and el =~ /^[0-9]+$/
            el = el.to_i
          end
          ret << el
        end
        ret
      end

      def rest()
        self[1..self.size-1]
      end
      def is_array_el?(el)
        el.kind_of?(Fixnum)
      end
    end

######################## TODO: see whichj of below is still used
    def self.get_legal_connections(parent_id_handle)
      c = parent_id_handle[:c]
      parent_id = IDInfoTable.get_id_from_id_handle(parent_id_handle)
      component_ds = get_objects_just_dataset(ModelHandle.new(c,:component),nil,{:parent_id => parent_id}.merge(FieldSet.opt([:id,:external_ref],:component)))
      attribute_ds = get_objects_just_dataset(ModelHandle.new(c,:attribute),nil,FieldSet.opt([:id,:external_ref,:component_component_id],:attribute))

      attribute_link_ds = get_objects_just_dataset(ModelHandle.new(c,:attribute_link))
      component_ds.graph(:inner,attribute_ds,{:component_component_id => :id}).graph(:left_outer,attribute_link_ds,{:input_id => :id}).where({:attribute_link__id => nil}).all
    end

    def self.get_legal_connections_wrt_endpoint(attribute_id_handle,parent_id_handle)
    end

   private
    def self.ret_function_if_can_determine(input_obj,output_obj)
      i_sem = input_obj[:semantic_type]
      return nil if i_sem.nil?
      o_sem = output_obj[:semantic_type]
      return nil if o_sem.nil?

      #TBD: haven't put in any rules if they have different seamntic types
      return nil unless i_sem.keys.first == o_sem.keys.first      
      
      sem_type = i_sem.keys.first
      ret_function_endpoints_same_type(i_sem[sem_type],o_sem[sem_type])
    end

    def self.ret_function_endpoints_same_type(i,o)
      #TBD: more robust is allowing for example output to be "database", which matches with "postgresql" and also to have version info, etc
      raise Error.new("mismatched input and output types") unless i[:type] == o[:type]
      return :equal if !i[:is_array] and !o[:is_array]
      return :equal if i[:is_array] and o[:is_array]
      return :concat if !i[:is_array] and o[:is_array]
      raise Error.new("mismatched input and output types") if i[:is_array] and !o[:is_array]
      nil
    end

    def get_input_attribute(opts={})
      return nil if self[:input_id].nil?
      get_object_from_db_id(self[:input_id],:attribute)
    end

    def get_output_attribute(opts={})
      return nil if self[:output_id].nil?
      get_object_from_db_id(self[:output_id],:attribute)
    end
  end
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
