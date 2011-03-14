module XYZ
  class Port < Model
    def self.get_attribute_info(port_id_handles)
      get_objects_in_set_from_sp_hash(port_id_handles,:columns => [:id,:attribute]).map do |r|
        {
          :id => r[:id],
          :attribute => r[:attribute_direct]||r[:attribute_nested]
        }
      end
    end

    def self.create_ports_for_external_attributes(node_id_handle,cmp_id_handle)
      component = cmp_id_handle.create_object()
      attrs_external = component.get_attributes_ports().select do |attr|
        attr[:port_is_external] and attr[:has_port_object]
      end
      return if attrs_external.empty?
      node_id = node_id_handle.get_id()

      new_ports = attrs_external.map do |attr|
        type = attr[:port_type] == "output" ? "l4" : "external"
        ref = port_ref(type,attr)
        hash = {
          :type => type,
          :ref => ref,
          :display_name => ref,
          :node_node_id => node_id,
          :port_direction => attr[:port_type]
        }
        hash.merge(attr[:port_type] == "input" ? {:external_attribute_id => attr[:id]} : {})
      end
      port_mh = node_id_handle.createMH(:model_name => :port, :parent_model_name => :node)
      opts = {:returning_sql_cols => [:ref,:id]}
      create_info = create_from_rows(port_mh,new_ports,opts)

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
          :display_name => ref,
          :external_attribute_id => attr[:id],
          :node_node_id => node_id,
          :containing_port_id => new_port_index[strip_type(ref)],
          :port_direction => "output"
        }
      end
      create_from_rows(port_mh,nested_ports)
    end

    def self.create_and_update_l4_ports_and_links?(parent_idh,link_info_list)
      ret = {:new_port_links => Array.new,:new_l4_ports => Array.new, :merged_external_ports => Array.new}
      return ret if link_info_list.empty?
      sample_attr = link_info_list.first[:input]
      node_mh = sample_attr.model_handle.createMH(:node)

      #compute indexed_input_external_ports
      input_node_idhs = link_info_list.inject({}) do |h,link_info|
        node_id = link_info[:input][:component_parent][:node_node_id]
        h.merge(node_id => node_mh.createIDH(:id => node_id))
      end.values
      indexed_input_external_ports = Node.get_ports(input_node_idhs).inject({}) do |h,port|
        index = port[:external_attribute_id]
        index ? h.merge(index => port) : h
      end

      output_node_idhs = link_info_list.inject({}) do |h,link_info|
        node_id = link_info[:output][:component_parent][:node_node_id]
        h.merge(node_id => node_mh.createIDH(:id => node_id))
      end.values
      attr_to_ports = Node.get_output_attrs_to_l4_input_ports(output_node_idhs)

      #for each input in link_info_list either it must be placed under an existing l4 port or a layer 4 port must be created for it
      #in all cases the input external port must be rerooted under the (existing or new l4 port)

      #compute input attribute to l4 output mapping
      input_attr_to_l4 = Hash.new
      l4_input_to_create = Array.new
      link_info_list.each do |link_info|
        add_to_l4_input_to_create = false
        output_id = link_info[:output][:id]
        input_attr = link_info[:input]
        unless ports = attr_to_ports[output_id]
          add_to_l4_input_to_create = true
        else
          input_node_id = input_attr[:component_parent][:node_node_id]
          unless port = ports.find{|p|p[:node_node_id] == input_node_id}
            add_to_l4_input_to_create = true
          else
            input_attr_to_l4[input_attr[:id]] = {:port_id => port[:id], :state => :existed} 
          end
        end
        if add_to_l4_input_to_create
          l4_input_to_create << input_attr.merge(:port => indexed_input_external_ports[input_attr[:id]])
        end
      end

      #create needed l4 ports and update input_attr_to_l4
      l4_idhs = create_l4_input_ports(l4_input_to_create)
      ret[:new_l4_ports] = l4_idhs.map{|idh|idh.get_id()}
      l4_input_to_create.each_with_index do |attr,i|
        input_attr_to_l4[attr[:id]] = {:port_id => l4_idhs[i].get_id(), :state =>  :created}
      end

      #create needed l4 port_links
      attr_links_for_port_links = link_info_list.select{|l|input_attr_to_l4[l[:input][:id]][:state] == :created}
      unless attr_links_for_port_links.empty?
        output_attr_idhs = attr_links_for_port_links.map{|link_info|link_info[:output].id_handle}.uniq
        output_attr_to_l4 = Attribute.get_port_info(output_attr_idhs).inject({}) do |h,port_info|
          h.merge(port_info[:port_external][:external_attribute_id] => port_info[:port_l4][:id])
        end

        l4_links_to_create = attr_links_for_port_links.map do |link_info|
          {:input_id => input_attr_to_l4[link_info[:input][:id]][:port_id],
            :output_id => output_attr_to_l4[link_info[:output][:id]]}
        end.uniq
        ret[:new_port_links] = PortLink.create(parent_idh,l4_links_to_create).map{|idh|idh.get_id()}
      end

      #reroot neeeded external ports
      reroot_info = link_info_list.map{|l|l[:input][:id]}.uniq.map do |attr_id|
        {
          :attribute_id => attr_id,
          :external_port_id => indexed_input_external_ports[attr_id][:id],
          :l4_port_id => input_attr_to_l4[attr_id][:port_id]
        }
      end
      ret[:merged_external_ports] = reroot_info.map{|r|Aux::hash_subset(r,[:external_port_id,:l4_port_id])}
      port_mh = parent_idh.createMH(:port)
      reroot_external_ports(port_mh,reroot_info)
      ret
    end
  
   private
    def self.reroot_external_ports(port_mh,reroot_info)
      return if reroot_info.empty?
      update_rows = reroot_info.map do |info|
        {
          :id => info[:external_port_id],
          :containing_port_id => info[:l4_port_id],
         }
      end
       update_from_rows(port_mh,update_rows)
    end

    def self.create_l4_input_ports(attrs_external)
      return Array.new if attrs_external.empty?
      new_l4_ports = attrs_external.map do |attr|
        node_id = attr[:component_parent][:node_node_id]
        type = "l4"
        ref = add_type(type,strip_type(attr[:port][:ref]))
        {
          :type => type,
          :ref => ref,
          :display_name => ref,
          :node_node_id => node_id,
          :port_direction => "input"
        }
      end
      sample = attrs_external.first
      model_handle = sample.model_handle.createMH(:model_name => :port, :parent_model_name => :node)
      create_from_rows(model_handle,new_l4_ports)
    end
   public
    #TODO: assumption that ref and display_name are teh same
    def component_name()
      self[:display_name].split("___")[1]
    end
    def attribute_name()
      self[:display_name].split("___")[2]
    end
    def ref_num()
      self[:display_name].split("___")[3].to_i
    end
   private
    def self.port_ref(type,attr)
      ref_num = (attr[:component_ref_num]||1).to_s
      "#{type}___#{attr[:component_ref]}___#{attr[:display_name]}___#{ref_num}"
    end
    
    def self.strip_type(ref)
      ref.gsub(/^[^_]+___/,"")
    end

    def self.add_type(type,stripped_ref)
      "#{type}___#{stripped_ref}"
    end
  end
end
