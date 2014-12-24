require 'securerandom'
module DTK
  module PuppetForge
    class LocalCopy < Hash
      attr_reader :base_install_dir,:module_dependencies
      def initialize(output_hash,base_install_dir,module_dependencies)
        super()
        merge!(output_hash)
        @base_install_dir = base_install_dir
        @module_dependencies = module_dependencies
      end

      def modules(opts={})
        self.class.modules(self['installed_modules']||[],opts)
      end

      def delete_base_install_dir?()
        self.class.delete_base_install_dir?(@base_install_dir)
      end
      def self.delete_base_install_dir?(base_install_dir)
        FileUtils.rm_rf(base_install_dir)
      end

      def self.random_install_dir()
        "/tmp/puppet/#{SecureRandom.uuid}"
      end

     private
      def self.modules(installed_modules,opts={})
        ret = Array.new
        installed_modules.each do |installed_module|
          # TODO: DTK-1794; put in logic that checks whether teh array :remove is inopts and if so does not put in any module that matches
          ret << Module.new(installed_module)
          deps = installed_module['dependencies']
          if deps and ! deps.empty?
            ret += modules(deps,opts)
          end
        end
        ret
      end
    end

  end
end
