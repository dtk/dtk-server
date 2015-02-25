module DTK; class ConfigAgent
  module Adapter; class Puppet
    module MetadataFile
      # used for parsing metadata.json when importing module from git (import-git)
      def self.parse?(impl_obj, provider = nil)
        ret = nil
        unless metadata_name = contains_metadata?(impl_obj, provider)
          return ret
        end
        type = impl_obj[:type]
        
        json_content = RepoManager.get_file_content(metadata_name,:implementation => impl_obj)

        content_hash = nil
        begin 
          content_hash = Aux.convert_to_hash(json_content,:json)
        rescue => e
          return ret
        end
        if type = impl_obj[:type]
          content_hash.merge!(:type => type)
        end
        content_hash.merge!(:type => type) if type
        dependencies = (content_hash['dependencies']||[]).map{|hash_dep|ExternalDependency.new(hash_dep)}
        content = convert_to_internal_form(content_hash)
        {:content => content, :dependencies => dependencies}
      end
      
     private
      def self.contains_metadata?(impl_obj, provider = nil)
        depth = provider.nil? ? 1 : 2
        RepoManager.ls_r(depth,{:file_only => true},impl_obj).find do |f|
          f.eql?("metadata.json") || f.eql?("#{provider}/metadata.json")
        end
      end

      def self.convert_to_internal_form(content_hash)
        content_hash.inject(Hash.new){|h,(k,v)|h.merge(k.to_sym => v)}
      end

      class ExternalDependency < Puppet::ExternalDependency
        def initialize(hash_content)
          super(hash_content['name'],hash_content['version_requirement'])
        end
      end
    end
  end; end
end; end



