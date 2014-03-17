module DTK; class ConfigAgent; module Adapter; class Puppet
  module ParserMixin
    module Modulefile
      # used for parsing Modulefile when importing module from git (import-git)
      def self.parse?(impl_obj)
        ret = nil
        unless modulefile_name = contains_modulefile?(impl_obj)
          return ret
        end
        
        content_hash, dependencies = {}, []
        type = impl_obj[:type]
        
        content = RepoManager.get_file_content(modulefile_name,:implementation => impl_obj)
        content.split("\n").each do |el|
          el.chomp!()
          next if (el.start_with?("#") || el.empty?)
          el.gsub!(/\'/,'')
          
          next unless match = el.match(/(\S+)\s(.+)/)
          key, value = match[1], match[2]
          if key.to_s.eql?('dependency')
              dependencies << value
          else
            content_hash.merge!(key.to_sym=>value.to_s)
          end
        end
        
        content_hash.merge!(:type => type) if type
        {:content => content_hash, :modulefile_name => modulefile_name, :dependencies => dependencies}
      end
      
     private
      def self.contains_modulefile?(impl_obj)
        depth = 1
        RepoManager.ls_r(depth,{:file_only => true},impl_obj).find do |f|
          f.eql?("Modulefile")
        end
      end
    end
  end
end; end; end; end


