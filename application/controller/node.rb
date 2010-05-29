

module XYZ
  class NodeController < Controller
    def discover_and_update_ec2
      filters = Hash.new
      #TBD: needs a project id handle to indicate where to store
      Node.discover_and_update(:ec2,filters)
      "discover ec2"
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
