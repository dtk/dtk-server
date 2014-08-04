module DTK; class NodeModuleDSL
  module UpdateModelMixin
    def update_model(opts={})
      Log.info("Here code is written that inserts that contents of @input_hash into objects of the form node_image")
      raise ErrorUsage.new("got here; pace where objects must be inserted")
      # TODO:
      # db_update_hash = ...
      #TODO:: this would do teh actual db insert 
      # Model.input_hash_content_into_model(@container_idh,db_update_hash)      
    end
  end
end; end

