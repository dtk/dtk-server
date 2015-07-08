require File.expand_path('get_cookbook_metadata', File.dirname(__FILE__))
require File.expand_path('get_node_data', File.dirname(__FILE__))

module XYZ
  class ChefProcessor
    def self.get_cookbooks_metadata(cookbooks_uri=nil,&block) #TBD nil is stub to use the default connection
      if cookbooks_uri =~ %r{^file://(.+$)}
        MetadataFromFile.new.get($1,&block)
      else
        MetadataFromServer.new.get(cookbooks_uri,&block)
      end
    end
    def self.get_nodes_data_from_server(_chef_server_uri=nil,&block) #TBD nil is stub to use the default connection
      NodeDataFromServer.new.get_nodes_data(chef_server_uri=nil,&block)
    end
  end
end

