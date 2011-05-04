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
      ret = Hash.new
      unravelled_ret.each do |r|
        target = ret[r[:target][:id]] ||= r[:target]
        nodes = target[:nodes] ||= Hash.new
        next unless r[:node]
        node = nodes[r[:node][:id]] ||= r[:node]
        components = node[:components] ||= Hash.new
        components[r[:component][:id]] = r[:component] if r[:component]
      end
      ret
    end
  end
end

