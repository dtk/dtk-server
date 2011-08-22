module XYZ
  class Attribute_linkController < Controller
    helper :ports
    def save(explicit_hash=nil,opts={})
      hash = explicit_hash || request.params.dup
      return Error.new("not implemented update of attribute link") if hash["id"]

      #TODO: right now call reaching here has port link attributes not attribute links; so should probably move this to under port link controller
      port_input_id,port_output_id = [hash["input_id"].to_i,hash["output_id"].to_i]
      port_idhs = [port_input_id,port_output_id].map{|id|id_handle(id,:port)}
      indexed_attrs = Port.get_attribute_info(port_idhs).inject({}){|h,r|h.merge(r[:id] => r)}
      attr_link = {
        :display_name => hash["name"],
        :input_id => indexed_attrs[port_input_id][:attribute][:id],
        :output_id => indexed_attrs[port_output_id][:attribute][:id]
      }

      temp_link_id = hash["temp_link_id"]

      handle_errors do
        parent_id_handle = id_handle(hash["parent_id"],hash["parent_model_name"])
        #TODO: many hacks to return new interface to front end
        port_update = AttributeLink.create_port_and_attr_links(parent_id_handle,[attr_link])
        new_id = port_update[:new_port_links].first
        if new_id 
          link = create_object_from_id(new_id,:port_link)
          link.update_object!(:input_id,:output_id)

          input_port = Port.create_object_from_id(link[:input_id])
          input_port.update!(*Port.common_columns())
          input_port_update_info =
            if not port_update[:new_l4_ports].empty?
              "replace_with_new"
            elsif not port_update[:merged_external_ports].empty?
              "merge"
            else
              "no_change"
            end
          input_port.merge!(:update_info => input_port_update_info)

          output_port = Port.create_object_from_id(link[:output_id])
          output_port.update!(*Port.common_columns())
          #only new ports created on input side
          output_port.merge!(:update_info => "no_change")
          
          ret = {
            :state => "new_link",                                                               
            :temp_link_id => temp_link_id,
            :link => link,
            :input_port => input_port,
            :output_port => output_port,
          }
        else
          ret = {
            :state => "existing_link",                                                               
            :temp_link_id => temp_link_id
          }
        end

puts "-------------------------"
pp ["new create link response:", ret]
puts "-------------------------"

        if hash["return_model"] == "true"
          return {:data=> 
              {
                :link =>get_object_by_id(new_id,:port_link),
                :link_changes => port_update
              }
            }
        end
    
        return new_id if opts[:return_id]
        redirect = (not (hash["redirect"].to_s == "false"))
        redirect "/xyz/#{model_name()}/display/#{new_id.to_s}" if redirect
      end
    end


    #TODO: right now just for testing
    def list_legal_connections(*parent_uri_array) #TODO stub
      parent_id = nil
      parent_uri = (parent_uri_array.empty? ? "/datacenter/dc1" : "/" + parent_uri_array.join("/"))
      parent_id = ret_id_from_uri(parent_uri)
      parent_model_name = "datacenter"
      #TODO: stubbed for just links under datacenters
      augmented_attributes = get_external_ports_under_datacenter(parent_id)
      #TODO stub to go from ports to form needed by view
      port_list = Array.new
      augmented_attributes.each do |row|
        port_list <<
          {
          :id => row[:id],
          :node_name => row[:node][:display_name],
          :component_name => row[:component][:display_name],
          :port_type => row[:port_type],
          :port_name => row[:display_name]
        }
      end
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{default_action_name()}",user_context())
      tpl.assign(:port_list,port_list)
      tpl.assign(:parent_id,parent_id)
      tpl.assign(:parent_model_name,parent_model_name)
      tpl.assign(:list_start_prev, 0)
      tpl.assign(:list_start_next, 0)
      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())
      tpl.assign("_#{model_name().to_s}",_model_var)

      return {:content => tpl.render()}
    end

    def list_on_node_ports(node_id=nil)
      aux_list_on_node_ports(node_id ? [node_id] : nil)
    end

=begin
      Params
            -<query filters>
            -context_list[
                          {'id':9493llskc393,'model':'node'},
                          {'id':3448dkwkr5,'model':'component'}
              ]
=end
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
