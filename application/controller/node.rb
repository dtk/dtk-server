

module XYZ
  class NodeController < Controller
    def discover_and_update(*uri_array)
      c = ret_session_context_id()
      provider_type = uri_array.pop.to_sym
      container_id_handle = IDHandle[:c => c, :uri => "/" + uri_array.join("/")]
      filters = Hash.new #TBD stub
      Node.discover_and_update(container_id_handle,provider_type,filters)
      "discover and update ec2"
    end

    def list
      #get all active (or appropriate status) ubuntu servers

      #figure out what best paradigm is to set which object/table to query against
      DB.set_object('node')
      DB.where('status','active')
      DB.where('os','ubuntu')
      DB.order_by('some_col','DESC')
      #by default return array of hashes
      nodes = DB.list

      #render to template
      R8.Template.set_view('node/workspace_list')

      #guess these would be class definitions for Controller that would include?
      #require_js('somejsfile')
      #require_css('somecss')

      #assign the node list to the proper var to be populated in the template
      R8.Template.assign(@nodeList,nodes)
      #process the template and assign/render the output to the 'toolbar' variable assignment
      #in parent template or bundled and returned in the JSON response
      R8.Template.render('toolbar')
    end
  end
end
