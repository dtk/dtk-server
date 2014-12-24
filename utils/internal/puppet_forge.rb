module DTK
  module PuppetForge
    r8_nested_require('puppet_forge','client')
    r8_nested_require('puppet_forge','local_copy')

    # user and name sepparator used by puppetforge
    MODULE_NAME_SEPARATOR = '-'
    def self.puppet_forge_namespace_and_module_name(pf_module_name)
      pf_module_name.split(MODULE_NAME_SEPARATOR, 2)
    end
    def self.puppet_forge_module_name(pf_module_name)
      puppet_forge_namespace_and_module_name(pf_module_name).last
    end

    class Module
      attr_reader :path
      def initialize(hash)
        @module  = hash['module']
        @version = hash['version']
        @file    = hash['file']
        @path    = "#{hash['path']}/#{PuppetForge.puppet_forge_module_name(@module)}"
      end

      def default_local_module_name
        PuppetForge.puppet_forge_module_name(@module)
      end
    end
  end
end
