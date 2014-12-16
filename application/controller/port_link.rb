module XYZ
  class Port_linkController < AuthController
    def save(explicit_hash=nil,opts={})
      raise Error.new("TODO: this is now deprecated: PortLink.create_port_and_attr_links__clone_if_needed has changed")
      hash = explicit_hash || request.params
      return Error.new("not implemented update of port link") if hash["id"]

      port_link = {
        :input_id => hash["input_id"].to_i,
        :ouput_id => hash["output_id"].to_i
      }
      parent_id_handle = id_handle(hash["parent_id"],hash["parent_model_name"])
      handle_errors do
        ret = PortLink.create_port_and_attr_links__clone_if_needed(parent_id_handle,[port_link])
        new_id = ret[:new_port_links].first
        if hash["return_model"] == "true"
          return {:data=> 
              {
                :link =>get_object_by_id(new_id,:port_link),
                :link_changes => ret
              }
            }
        end
    
        return new_id if opts[:return_id]
        redirect = (not (hash["redirect"].to_s == "false"))
        redirect "/xyz/#{model_name()}/display/#{new_id.to_s}" if redirect
      end
    end
  end
end

