module XYZ
  module ImportComponentMeta
    def self.add_or_update_component(parent_idh,component_name,opts={})
      component_hash = get_r8meta_hash(component_name,opts)
      add_implementation_id!(component_hash,parent_idh,component_name)
      Model.input_into_model(parent_idh,component_hash)
    end

   private
    def self.get_r8meta_hash(component_name,opts={})
      r8meta_type = opts[:r8meta_type]
      r8meta_file = find_r8meta_file(component_name,r8meta_type)
      ret = nil
      case r8meta_type 
       when :yaml
        require 'yaml'
        ret = YAML.load_file(r8meta_file)
       else
        raise Error.new("Type #{r8meta_type} not supported")
      end
      ret
    end

    def self.find_r8meta_file(component_name,r8meta_type)
      file_ext = TypeMapping[r8meta_type]
      raise Error.new("illegal type extension") unless file_ext
      repo = component_name.gsub(/__.+$/,"")
      files = Dir.glob("#{R8::EnvironmentConfig::CoreCookbooksRoot}/#{repo}/r8meta.*.#{file_ext}")
      if files.empty?
        raise Error.new("Cannot find valid r8meta file")
      elsif files.szie > 1
        raise Error.new("Multiple r8meta files found")
      end
      files.first
    end
    TypeMapping = {
      :yaml => "yml"
    }
    
    def self.add_implementation_id!(component_hash,parent_idh,component_name)
      impl_display_name = component_name.gsub(/__.+$/,"")
      sp_hash = {
        :cols => [:id],
        :filter => [:and, [:eq, :display_name, impl_display_name],
                    [:eq, DB.parent_field(parent_idh[:model_name],:implementation), parent_idh.get_id()]]
      }
      rows = Model.get_objects_from_sp_hash(parent_idh.createMH(:implementation),sp_hash)
      raise Error.new("Error in finding implementation for component #{component_name}") unless rows.size = 1
      component_hash.merge!(:implementation_id => rows.first[:id])
    end
  end
end
