module XYZ
  class Implementation < Model
    def create_pending_change_item(file_asset)
      get_objects_from_sp_hash({:cols => [:component_info]}).each do |r|
        cmp_idh = r[:component].id_handle()
        parent_idh = cmp_idh.createIDH(:model_name => :datacenter, :id => r[:node][:datacenter_datacenter_id])
        StateChange.create_pending_change_item(:new_item => cmp_idh, :parent => parent_idh)
      end
    end
  end
end

