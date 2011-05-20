module XYZ
  class Project < Model
    #Model apis
    def self.get_all(model_handle)
      sp_hash = {:cols => [:id,:display_name,:type]}
      get_objects_from_sp_hash(model_handle,sp_hash)
    end

    def get_implementaton_tree(opts={})
      sp_hash = {:cols => [:id,:display_name,:type,:implementation_tree]}
      unravelled_ret = get_objects_from_sp_hash(sp_hash)
      ret_hash = Hash.new
      unravelled_ret.each do |r|
        unless cmp = ret_hash[r[:component][:id]] 
          cmp = ret_hash[r[:component][:id]] = r[:component].reject{|k,v|[:node_node_id,:implementation_id].include?(k)}
        end
        impls = cmp[:implementations] ||= Hash.new
        impls[r[:implementation][:id]] ||= r[:implementation]
      end
      ret = ret_hash.values.map{|ct|ct.merge(:implementations => ct[:implementations].values)}
      return ret unless opts[:include_file_assets]
      
      impl_idhs = ret.map{|ct|ct[:implementations].map{|impl|impl.id_handle}}.flatten(1)
      indexed_asset_files = Implementation.get_indexed_asset_files(impl_idhs)
      ret.each{|ct|ct[:implementations].each{|impl|impl.merge!(:file_assets => indexed_asset_files[impl[:id]])}}
      ret
    end

    def get_target_tree()
      sp_hash = {:cols => [:id,:display_name,:type,:target_tree]}
      unravelled_ret = get_objects_from_sp_hash(sp_hash)
      ret_hash = Hash.new
      unravelled_ret.each do |r|
        unless target = ret_hash[r[:target][:id]]
          target = ret_hash[r[:target][:id]] ||= r[:target].reject{|k,v|k == :project_id}.merge(:model_name => "target")
        end
        nodes = target[:nodes] ||= Hash.new
        next unless r[:node]
        unless node = nodes[r[:node][:id]] 
          node = nodes[r[:node][:id]] = r[:node].reject{|k,v|[:datacenter_datacenter_id].include?(k)}
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

