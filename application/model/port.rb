module XYZ
  class Port < Model
    def self.create_ports_for_external_attributes(node_id_handle,cmp_id_handle)
      component = cmp_id_handle.create_object()
      attrs_external = component.get_objects_col_from_sp_hash({:columns => [:attributes_port]},:attribute).select{|a|a[:port_is_external]}
      return if attrs_external.empty?
      node_id = node_id_handle.get_id()

      new_ports = attrs_external.map do |attr|
        hash = {
          :type => attr[:port_type] == "output" ? "l4" : "external",
          :ref => attr[:ref],
          :display_name => attr[:display_name],
          :node_node_id => node_id
        }
        hash.merge(attr[:port_type] == "input" ? {:external_attribute_id => attr[:id]} : {})
      end
      model_handle = node_id_handle.createMH(:model_name => :port, :parent_model_name => :node)
      opts = {:returning_sql_cols => [:ref,:id]}
      create_info = create_from_rows(model_handle,new_ports,opts)

      #for output ports need to nest in l4 ports
      output_attrs = attrs_external.select{|a|a[:port_type] == "output"}
      return if output_attrs.empty?
      new_port_index = create_info.inject({}){|h,idh|h.merge(idh[:ref] => idh.get_id())}
      nested_ports = output_attrs.map do |attr|
        {
          :type => "external",
          :ref => attr[:ref],
          :display_name => attr[:display_name],
          :external_attribute_id => attr[:id],
          :containing_node_id => node_id,
          :port_id => new_port_index[attr[:ref]]  
        }
      end
      nested_mh = node_id_handle.createMH(:model_name => :port, :parent_model_name => :port)
      create_from_rows(nested_mh,nested_ports)
    end

    def self.create_and_update_l4_ports?(link_info_list)
      return #TODO: working on below
      indexed_attrs = Hash.new
      link_info_list.each do |link_info|
        indexed_attrs[link_info[:output][:id]] ||= link_info[:output]
        indexed_attrs[link_info[:input][:id]] ||= link_info[:input]
      end
      attr_idhs = indexed_attrs.values.map{|a|a.id_handle}
      conn_ports = get_objects_in_set_from_sp_hash(attr_idhs,{:cols => [:port]}).map{|r|r[:port]}
      conn_ports
    end
  end

  class PortList
    def self.create(type,node_id_handles=nil)
      case type
      when "external" then PortListExternal.new() 
      when "l4" then PortListL4.new().set_context(node_id_handles) 
      else PortList.new
      end
    end
    def attr_is_pruned?(attr)
      false
    end
    def link_is_pruned?(link)
      false
    end
    
    def add_or_collapse_attribute!(attr,cmp)
      @top_level << attr
    end
    def top_level()
      @top_level
    end

    def get_input_port_link_info(node_id_handles)
      input_port_cols = [:id, :display_name, :input_port_links]
      Model.get_objects_in_set_from_sp_hash(node_id_handles,:columns => input_port_cols).reject do |r|
        attr_is_pruned?(r[:attribute]) or attr_is_pruned?(r[:attr_other_end]) or link_is_pruned?(r[:attribute_link])
      end
    end
    def get_output_port_link_info(node_id_handles)
      output_port_cols = [:id, :display_name, :output_port_links]
      Model.get_objects_in_set_from_sp_hash(node_id_handles,:columns => output_port_cols).reject do |r|
        attr_is_pruned?(r[:attribute]) or attr_is_pruned?(r[:attr_other_end]) or link_is_pruned?(r[:attribute_link])
      end
    end
    private
    def initialize()
      @top_level = Array.new
    end
  end

  class PortListExternal < PortList
    def attr_is_pruned?(attr)
      not attr[:port_is_external]
    end
  end

  class PortListL4 < PortListExternal
    def initialize()
      super
      @equiv_classes = Hash.new
      @ports_other_end = nil
    end
    
    def attr_is_pruned?(attr)
      not %w{sap_ref__l4 sap__l4}.include?(attr[:display_name])
    end
    def link_is_pruned?(link)
      not link[:type] == "external"
    end

    def add_or_collapse_attribute!(attr,cmp)
      equiv_class = ret_equiv_class(attr,cmp)
      @equiv_classes[equiv_class] ||= Array.new
      @equiv_classes[equiv_class] << attr
    end
    def top_level()
      @equiv_classes.values.map{|equiv_class|attr_with_min_id(equiv_class)}
    end

    def set_context(node_id_handles)
      return self unless node_id_handles and not node_id_handles.empty?
      # @indexed_port_links = get_input_port_link_info(node_id_handles).inject ..
      @ports_other_end = get_input_port_link_info(node_id_handles).inject({}) do |h,link_info|
        #implicit assumption is that theer is just one link conencted to l4 input
        h.merge(link_info[:attribute][:id] => link_info[:attr_other_end][:id])
      end
      self
    end

   private
    def ret_equiv_class(attr,cmp)
      #TODO: if not connected then using attr own id to make unconencted ports show up
      @ports_other_end[attr[:id]]||attr[:id]
    end
      
    def attr_with_min_id(attrs)
      ret = attrs.first
      attrs[1..attrs.size-1].each do |a|
        ret = a if a[:id] < ret[:id]
      end
      ret
    end
  end
end
