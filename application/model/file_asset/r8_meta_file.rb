module XYZ
  module FileAssetR8MetaFile
    class R8MetaFile
      #creates if file_obj is a r8meta file
      def self.isa?(file_obj,content)
        return nil unless file_obj[:path] =~ /^r8meta\.([a-z]+)\.([a-z]+$)/
        config_agent_type = $1.to_sym
        file_extension = $2
        format_type = ExtensionToType[file_extension]
        raise Error.new("illegal fiel extension #{file_extension}") unless file_extension
        impl_idh = file_obj[:implementation].id_handle()
        file_idh =  file_obj.id_handle()
        hash_content = convert_to_hash(format_type,content)
        self.new(config_agent_type,impl_idh,file_idh,hash_content)
      end
      ExtensionToType = {
        "yml" => :yaml
      }

      def initialize(config_agent_type,impl_idh,file_idh,hash_content)
        @config_agent_type = config_agent_type
        @hash_content = hash_content
        @impl_idh = impl_idh
        @file_idh = file_idh
      end
      def process()
        #TODO: right now just processing changes to link defs
        ndx_cmps_to_update = Hash.new
        process_external_link_defs!(ndx_cmps_to_update)
        return if ndx_cmps_to_update.empty?
      end
     private
      def process_external_link_defs!(ndx_cmps_to_update)
        link_defs = @hash_content.inject({}) do |h,(cmp_type,info)|
          h.merge(cmp_type => info["external_link_defs"])
        end
        return if link_defs.empty?
        #get the matching components in the project implementation and their instantaions
        updates = get_matching_components(link_defs.keys)
        if updates.empty?
          Log.error("unexpected that cant find any components that match")
          return 
        end
        updates.each do |r|
          p = ndx_cmps_to_update[r[:id]] ||= {:id => r[:id]} 
          p[:link_defs] ||= Hash.new
          p[:link_defs]["external"] = link_defs[r[:component_type]]
        end
      end
      def get_matching_components(cmp_type_array)
        sp_hash = {
          :model_name => :component,
          :filter => [:and, [:eq, :implementation_id, @impl_idh.get_id()],
                      [:oneof, :component_type, cmp_type_array]],
          :cols => [:id,:component_type]
        }
        Model.get_objs(@impl_idh.createMH(:component),sp_hash)
      end

      def self.convert_to_hash(format_type,content)
        case format_type
         when :yaml then convert_to_hash_yaml(content)
        else
          raise Error.new("cannot treat format type #{format_type}")
        end
      end
      def self.convert_to_hash_yaml(content)
        #TODO: raise parsing error to user
        YAML.load(content)
      end
    end
  end
end
