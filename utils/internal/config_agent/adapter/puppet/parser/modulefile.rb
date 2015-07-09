module DTK; class ConfigAgent
  module Adapter; class Puppet
    module Modulefile
      # used for parsing Modulefile when importing module from git (import-git)
      def self.parse?(impl_obj)
        ret = nil
        unless modulefile_name = contains_modulefile?(impl_obj)
          return ret
        end

        content_hash, dependencies = {}, []
        type = impl_obj[:type]

        content = RepoManager.get_file_content(modulefile_name, implementation: impl_obj)
        content.split("\n").each do |el|
          el.chomp!()
          next if (el.start_with?('#') || el.empty?)
          el.gsub!(/\'/, '')

          next unless match = el.match(/(\S+)\s(.+)/)
          key, value = match[1], match[2]
          if key.to_s.eql?('dependency')
            dependencies << ExternalDependency.new(value)
          end
          content_hash.merge!(key.to_sym => value.to_s)
        end

        content_hash.merge!(type: type) if type
        { content: content_hash, modulefile_name: modulefile_name, dependencies: dependencies }
      end

      private

      def self.contains_modulefile?(impl_obj)
       depth = 2
       RepoManager.ls_r(depth, { file_only: true }, impl_obj).find do |f|
          f.eql?('Modulefile') || f.eql?("#{Puppet.provider_folder()}/Modulefile")
        end
      end

      class ExternalDependency < Puppet::ExternalDependency
        def initialize(string_info)
          name, version = string_info.split(',')
          version.strip! if version
          super(name, version)
        end
      end
    end
  end; end
end; end
