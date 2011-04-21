module XYZ
  class FileAsset < Model
    #model apis
    def self.get_file_asset(component_idh,file_name)
      sp_hash = {
        :model_name => :file_asset,
        :filter => [:eq, :file_name, file_name],
        :cols => [:id,:content]
      }
      component_idh.create_object().get_children_from_sp_hash(:file_asset,sp_hash).first
    end

#stubs for further methods
=begin
    def save_as(new_name)
    end
    def delete()
    end
    def save()
    end

=end
  end
end

