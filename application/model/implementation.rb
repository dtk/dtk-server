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
   private
    FileAssetType = { 
      :chef_cookbook => "chef_file"
    }
   public

    def find_match_in_project(project_idh)
      base_sp_hash = {
        :model_name => :implementation,
        :filter => [:eq, :id, id()],
        :cols => [:repo, :version_num]
      }
      join_array = 
        [{
           :model_name => :implementation,
           :alias => :proj_impl,
           :convert => true,
           :join_type => :inner,
           :filter => [:eq, :project_project_id, project_idh.get_id()],
           :join_cond => {:repo => :implementation__repo, :version_num => :implementation__version_num},
           :cols => [:id,:repo,:version_num]
         }]

      row = Model.get_objects_from_join_array(model_handle(),base_sp_hash,join_array).first
      row && row[:proj_impl].id_handle()
    end

    def add_model_specific_override_attrs!(override_attrs,target_obj)
      override_attrs[:updated] ||= false
    end

    #self is a project implementation; returns library implementation idh
    def clone_into_library_if_needed(library_idh)
      ret = nil
      #if implementation is updated, need to create a new implemntation in library; otherwise use
      get_object_cols_and_update_ruby_obj!(:updated,:repo,:version_num)
      if self[:updated]
        new_version_num = get_new_version_num(library_idh)
        override_attrs={:version_num => new_version_num}
        new_impl_id = library_idh.create_object.clone_into(self,override_attrs)
        ret = library_idh.createIDH(:model_name => :implemntation, :id => new_impl_id)
      else
        impl_obj = matching_library_template_exists?(self[:version_num],library_idh)
        raise Error.new("expected to find a matching library implemntation") unless impl_obj
        ret = impl_obj.id_handle
      end
      ret
    end

    def set_to_indicate_updated()
      #TODO: short cut and avoid setting updated on project templates if impl set to updated already update({:updated => true},{:update_only_if_change => true})
      update(:updated => true)
      #set updated for the project templates that point to this implemntation
      fs = FieldSet.opt([:updated,:id],:component)
      wc = {:implementation_id => id(), :type => "template"}
      cmp_mh = model_handle.createMH(:component)
      update_ds = Model.get_objects_just_dataset(cmp_mh,wc,fs)
      Model.update_from_select(cmp_mh,FieldSet.new(:component,[:updated]),update_ds)    
    end

    def create_pending_change_item(file_asset)
      #TODO: make more efficient by using StateChange.create_pending_change_items
      get_objects_from_sp_hash({:cols => [:component_info]}).each do |r|
        cmp_idh = r[:component].id_handle()
        parent_idh = cmp_idh.createIDH(:model_name => :datacenter, :id => r[:node][:datacenter_datacenter_id])
        StateChange.create_pending_change_item(:new_item => cmp_idh, :parent => parent_idh, :type => "update_implementation")
      end
    end

   private

    def get_new_version_num(library_idh)
      #TODO: potential race condition in getting new version
      sp_hash = {:cols => [:version_num],:filter => [:eq, :library_library_id, library_idh.get_id()]}
      existing_ver_nums = get_objects_from_sp_hash(library_idh.model_handle(:implementatation),sp_hash).map{|r|r[:version_num]}
      1 + (existing_ver_nums.max||0)
    end

    def matching_library_template_exists?(version_num,library_idh)
      sp_hash = {
        :cols => [:id],
        :filter => [:and, 
                     [:eq, :library_library_id, library_idh.get_id()],
                     [:eq, :version_num, version_num],
                     [:eq, :repo, self[:repo]]]
      }
      Model.get_objects_from_sp_hash(model_handle,sp_hash).first
    end
  end
end

