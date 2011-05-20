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
        file_asset = r[:file_asset].reject{|k,v|k == :implementation_implementation_id}
        FileAsset.set_hierrachical_file_struct!(pointer,file_asset)
      end
      ret
    end

    def add_asset_file(path,content=nil)
      impl_obj = add_cols_if_not_present(:type,:repo)
      impl_type = impl_obj[:type]
      file_asset_type = FileAssetType[impl_type.to_sym]
      FileAsset.add(impl_obj,file_asset_type,path,content)
    end

    def find_match_in_project(project_idh)
      base_sp_hash = {
        :model_name => :implementation,
        :filter => [:eq, :id, id()],
        :cols => [:repo]
      }
      join_array = 
        [{
           :model_name => :implementation,
           :alias => :proj_impl,
           :convert => true,
           :join_type => :inner,
           :filter => [:eq, :project_project_id, project_idh.get_id()],
           :join_cond => {:repo => :implementation__repo},
           :cols => [:id,:repo]
         }]

      row = Model.get_objects_from_join_array(model_handle(),base_sp_hash,join_array).first
      row && row[:proj_impl].id_handle()
    end
   private
    FileAssetType = { 
      :chef_cookbook => "chef_file"
    }
   public

    def create_pending_change_item(file_asset)
      #TODO: make more efficient by using StateChange.create_pending_change_items
      get_objects_from_sp_hash({:cols => [:component_info]}).each do |r|
        cmp_idh = r[:component].id_handle()
        parent_idh = cmp_idh.createIDH(:model_name => :datacenter, :id => r[:node][:datacenter_datacenter_id])
        StateChange.create_pending_change_item(:new_item => cmp_idh, :parent => parent_idh, :type => "update_implementation")
      end
    end
  end
end

