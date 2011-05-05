module XYZ
  class Project < Model
    #Model apis
    def self.get_all(model_handle)
      sp_hash = {:cols => [:id,:display_name,:type]}
      get_objects_from_sp_hash(model_handle,sp_hash)
    end

    def get_tree()
      sp_hash = {:cols => [:id,:display_name,:type,:tree]}
      unravelled_ret = get_objects_from_sp_hash(sp_hash)
      ret_hash = Hash.new
      unravelled_ret.each do |r|
        unless target = ret_hash[r[:target][:id]]
          target = ret_hash[r[:target][:id]] ||= r[:target].reject{|k,v|k == :project_id}.merge(:model_name => "target")
        end
        nodes = target[:nodes] ||= Hash.new
        next unless r[:node]
        unless node = nodes[r[:node][:id]] 
          node = nodes[r[:node][:id]] = r[:node].reject{|k,v|k == :datacenter_datacenter_id}
        end
        components = node[:components] ||= Hash.new
        components[r[:component][:id]] = r[:component].reject{|k,v|k == :node_node_id} if r[:component]
      end
      ret_hash.values.map do |t|
        nodes = t[:nodes].values.map do |n|
          n.merge(:components => n[:components].values)
        end
        t.merge(:nodes => nodes)
      end
    end
  end
end

