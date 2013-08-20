module XYZ
  class Attribute_linkController < AuthController

    #deprecate for Port_linkController#save
    def save(explicit_hash=nil,opts={})
      raise Error.new("TODO: this is now deprecated: PortLink.create_port_and_attr_links has changed")
      hash = explicit_hash || request.params
      return Error.new("not implemented update of port link") if hash["id"]

      port_link_hash = {
        :input_id => hash["input_id"].to_i,
        :output_id => hash["output_id"].to_i
      }

      temp_link_id = hash["temp_link_id"]

      handle_errors do
        parent_id_handle = id_handle(hash["parent_id"],hash["parent_model_name"])
        #TODO: many hacks to return new interface to front end
        link = PortLink.create_port_and_attr_links(parent_id_handle,port_link_hash)
        new_id = link.id

        link.update_object!(:input_id,:output_id)
        link[:ui] ||= {
          :type => R8::Config[:links][:default_type],
          :style => R8::Config[:links][:default_style]
        }

        input_port = create_object_from_id(link[:input_id],:port)
        input_port.update_and_materialize_object!(*Port.common_columns())

=begin TODO: needs to be removed or modified        
        port_merge_info = port_update[:merged_external_ports].first
        if not port_update[:new_l4_ports].empty?
          input_port.merge!(:update_info => "replace_with_new", :replace_id => port_merge_info[:external_port_id])
        elsif port_merge_info and not port_merge_info.empty?
          input_port.merge!(:update_info => "merge", :merge_id => port_merge_info[:external_port_id])
        else
          input_port.merge!(:update_info => "no_change")
        end
=end
        input_port.merge!(:update_info => "no_change")

        output_port = create_object_from_id(link[:output_id],:port)
        output_port.update_and_materialize_object!(*Port.common_columns())
        #only new ports created on input side
        output_port.merge!(:update_info => "no_change")
          
       ret = {
          :temp_link_id => temp_link_id,
          :link => link,
          :input_port => input_port,
          :output_port => output_port,
        }
        {:data=>ret}
      end
    end

    def list_on_node_ports(node_id=nil)
      aux_list_on_node_ports(node_id ? [node_id] : nil)
    end

    def get_under_context_list(explicit_hash=nil)

      hash = explicit_hash || request.params
      context_list = JSON.parse(hash["context_list"])
      item_id_handles = context_list.map{|x|id_handle(x["id"].to_i,x["model"].to_sym)}
      link_list = Target.get_links(item_id_handles)
      return {'data'=>link_list}
    end

    def get_under_context(explicit_hash=nil)
      hash = explicit_hash || request.params
=begin
2) Get all links from a single object: <base uri>/attribute_link/get_under_context
      Params
            -<query filters>
            -id = 9493llskc393
            -model = node
=end
      raise Error.new("id not given") unless hash["id"]
      raise Error.new("only node type treated at this time") unless hash["model"] == "node"

      aux_list_on_node_ports([hash["id"].to_i])
    end

    #TODO: temp
    def aux_list_on_node_ports(node_ids)
      filter = node_ids ? [:and, [:oneof, :id, node_ids]] : nil
      cols = [:id,:display_name,:deprecate_port_links]
      field_set = Model::FieldSet.new(:node,cols)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      ds = ds.where(SQL.not(SQL::ColRef.coalesce(:other_end_output_id,:other_end_input_id) => nil))

      raw_link_list = ds.all
      link_list = Array.new
      raw_link_list.each do |el|
        component_name = el[:component][:display_name].gsub(/::.+$/,"")
        port_name = Aux.put_in_bracket_form([component_name] + Aux.tokenize_bracket_name(el[:attribute][:display_name]))
        type = (el[:attribute_link]||{})[:type]||(el[:attribute_link2]||{})[:type]
        hidden = (el[:attribute_link]||{})[:hidden].nil? ? (el[:attribute_link2]||{})[:hidden] : (el[:attribute_link]||{})[:hidden]
        other_end_id = (el[:attribute_link]||{})[:other_end_output_id]||(el[:attribute_link2]||{})[:other_end_input_id]
        port_dir = el[:attribute_link] ? "input" : "output"
        link_list << {
          :node_id => el[:id],
          :node_name => el[:display_name],
          :port_id => el[:attribute][:id],
          :port_name => port_name,
          :type => type,
          :port_dir => port_dir,
          :hidden => hidden,
          :other_end_id => other_end_id
        }
      end
pp '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
pp link_list

      action_name = "list_on_node_ports"
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{action_name}",user_context())
      tpl.assign("link_list",link_list)
      return {:content => tpl.render()}
    end
  end
end
