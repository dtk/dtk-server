

module XYZ
  class NodeController < Controller

    def list
      error_405 unless request.get?

=begin
      field_set = [
        :id,
        :name,
        :os,
        :disk,
        :memory,
        :source,  #amazon,local,rackspace, etc
        :status,
      ]
=end   
      field_set = [
        :id,
        :name,
        :description,
        :type,
        :os,
        :data_source
      ]   
      where_clause = {} # stub
      raw_objs = get_objects(:node,where_clause)
      #TBD: this logic below will be folded into get_objects
      objs = Hash.new
      raw_objs.each{|k,v| objs[k] = HashObject.object_slice(v,field_set,{:include_null_cols => true})}
      return objs
      require 'pp'; pp objs
      @results = Hash.new
=begin
      #get all active (or appropriate status) ubuntu servers

      #figure out what best paradigm is to set which object/table to query against
      DB.set_object('node')
      DB.where('status','active')
      DB.where('os','ubuntu')
      DB.order_by('some_col','DESC')
      #by default return array of hashes
      nodes = DB.list

      #render to template
      template_reference = R8.Template.set_view('node/workspace_list')
    

      #guess these would be class definitions for Controller that would include?
      #require_js('somejsfile')
      #require_css('somecss')

      #assign the node list to the proper var to be populated in the template
      bindings = R8.Template.assign(@nodeList,nodes)
      #process the template and assign/render the output to the 'toolbar' variable assignment
      #in parent template or bundled and returned in the JSON response
      R8.Template.render(template_reference,bindings,'toolbar')
=end
    end
  end
end
