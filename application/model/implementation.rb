module XYZ
  class Implementation < Model
    def get_asset_files()
      flat_file_assets = get_objects_col_from_sp_hash({:cols => [:file_assets]},:file_asset).reject{|k,v|k == :implementation_implementation_id}
      FileAsset.ret_hierrachical_file_struct(flat_file_assets)
    end

    #indexed by implementation_id
    def self.get_indexed_asset_files(id_handles)
      flat_file_assets = get_objects_in_set_from_sp_hash(id_handles,{:cols => [:id,:file_assets]})
      ret = Hash.new
      flat_file_assets.each do |r|
        pointer = ret[r[:id]] ||= Array.new
        FileAsset.set_hierrachical_file_struct!(pointer,r[:file_asset].reject{|k,v|k == :implementation_implementation_id})
      end
      ret
    end

    def create_pending_change_item(file_asset)
      get_objects_from_sp_hash({:cols => [:component_info]}).each do |r|
        cmp_idh = r[:component].id_handle()
        parent_idh = cmp_idh.createIDH(:model_name => :datacenter, :id => r[:node][:datacenter_datacenter_id])
        StateChange.create_pending_change_item(:new_item => cmp_idh, :parent => parent_idh, :type => "update_implementation")
      end
    end
  end
end

