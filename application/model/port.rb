module XYZ
  class Port < Model
    def self.create_ports_for_external_attributes(node_id_handle,cmp_id_handle)
      component = cmp_id_handle.create_object()
      attrs_external = component.get_attributes_ports().select{|a|a[:port_is_external]}
      return if attrs_external.empty?
      node_id = node_id_handle.get_id()

      new_ports = attrs_external.map do |attr|
        type = attr[:port_type] == "output" ? "l4" : "external"
        ref = port_ref(type,attr)
        hash = {
          :type => type,
          :ref => ref,
          :display_name => attr[:display_name],
          :containing_node_id => node_id,
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
      new_port_index = create_info.inject({}){|h,ret_info|h.merge(strip_type(ret_info[:ref]) => ret_info[:id])}

      nested_ports = output_attrs.map do |attr|
        type = "external"
        ref = port_ref(type,attr)
        {
          :type => type,
          :ref => ref,
          :display_name => attr[:display_name],
          :external_attribute_id => attr[:id],
          :containing_node_id => node_id,
          :port_id => new_port_index[strip_type(ref)]
        }
      end
      nested_mh = node_id_handle.createMH(:model_name => :port, :parent_model_name => :port)
      create_from_rows(nested_mh,nested_ports)
    end

    def self.create_and_update_l4_ports?(link_info_list)
      return #TODO working on below
      return if link_info_list.empty?
      sample_attr = link_info_list.first[:input]
      node_mh = sample_attr.model_handle.createMH(:node)

      #compute indexed_input_ports
      input_node_idhs = link_info_list.inject({}) do |h,link_info|
        node_id = link_info[:input][:component_parent][:node_node_id]
        h.merge(node_id => node_mh.createIDH(:id => node_id))
      end.values
      indexed_input_ports = Node.get_ports(input_node_idhs).inject({}) do |h,port|
        index = port[:external_attribute_id]
        index ? h.merge(index => port) : h
      end

      output_node_idhs = link_info_list.inject({}) do |h,link_info|
        node_id = link_info[:output][:component_parent][:node_node_id]
        h.merge(node_id => node_mh.createIDH(:id => node_id))
      end.values
      output_port_info = Node.get_output_ports_with_links(output_node_idhs)

      #for each input in link_info_list either it must be placed under an existing l4 port or a layer 4 port must be created for it
      #in all cases the input external port must be rerooted under the (existing or new l4 port)

      #for each attribute pointed to in output_port_info find the l4 port that its in and the othr end l4 port
      port_links = Hash.new
      output_port_info.each do |port_info|
        output_port = port_info[:port]
        next unless output_port[:type] == "l4"
        next unless other_end = port_info[:port_other_end]
        index = output_port[:id]
        port_links[index] ||= Array.new
        port_links[index] << other_end
      end

      #TODO: can this be directly computed by joins, rather than needing to do these "joins" in Ruby
      #this contains output attribute to input l4 ports
      attr_to_ports = Hash.new
      unless port_links.empty?
        output_port_info.each do |port_info|
          output_port = port_info[:port]
          next unless output_port[:type] == "external"
          index = output_port[:external_attribute_id]
          output_port = port_links[output_port[:port]]
          attr_to_ports[index] = output_port if output_port
        end
      end

      #compute input to l4 mapping
      input_to_l4 = Hash.new
      l4_to_create = Array.new
      link_info_list.each do |link_info|
        add_to_l4_to_create = false
        output_id = link_info[:output][:id]
        input_attr = link_info[:input]
        unless ports = attr_to_ports[output_id]
          add_to_l4_to_create = true
        else
          input_node_id = input_attr[:component_parent][:node_node_id]
          unless port = ports.find{|p|p[:node_node_id] == input_node_id}
            add_to_l4_to_create = true
          else
            input_to_l4[input_attr[:id]] = port[:id] 
          end
        end
        if add_to_l4_to_create
          l4_to_create << input_attr.merge(:port => indexed_input_ports[input_attr[:id]])
        end
      end

      l4_idhs = create_l4_ports(l4_to_create)
      l4_to_create.each_with_index do |attr,i|
        input_to_l4[attr[:id]] = l4_idhs[i].get_id() 
      end

      l4_idhs
    end
  
   private
    def self.create_l4_ports(attrs_external)
      return Array.new if attrs_external.empty?
      new_l4_ports = attrs_external.map do |attr|
        node_id = attr[:component_parent][:node_node_id]
        type = "l4"
        ref = add_type(type,strip_type(attr[:port][:ref]))
        {
          :type => type,
          :ref => ref,
          :display_name => attr[:display_name],
          :containing_node_id => node_id,
          :node_node_id => node_id
        }
      end
      sample = attrs_external.first
      model_handle = sample.model_handle.createMH(:model_name => :port, :parent_model_name => :node)
      create_from_rows(model_handle,new_l4_ports)
    end
   private
    def self.port_ref(type,attr)
      "#{type}___#{attr[:component_ref]}___#{attr[:ref]}"
    end
    
    def self.strip_type(ref)
      ref.gsub(/^[^_]+___/,"")
    end

    def self.add_type(type,stripped_ref)
      "#{type}___#{stripped_ref}"
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
