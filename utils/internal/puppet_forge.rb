module DTK
  module PuppetForge
    r8_nested_require('puppet_forge','client')
    r8_nested_require('puppet_forge','local_copy')

    # user and name sepparator used by puppetforge
    MODULE_NAME_SEPARATOR = '-'

    # returns [pf_namespace,pf_module_name]
    def self.puppet_forge_namespace_and_module_name(pf_module_name)
      pf_module_name.split(MODULE_NAME_SEPARATOR, 2)
    end

    def self.puppet_forge_module_name(pf_module_name)
      puppet_forge_namespace_and_module_name(pf_module_name).last
    end

    def self.index(namespace,name)
      "#{namespace}-#{name}"
    end

    class Module

      attr_reader   :path, :name, :is_dependency
      attr_accessor :namespace, :dependencies

      def initialize(hash, is_dependency = false, type = :component_module, dtk_version = nil)
        m_namespace, m_name = PuppetForge.puppet_forge_namespace_and_module_name(hash['module'])

        @name          = m_name
        @namespace     = m_namespace
        @is_dependency = is_dependency
        @type          = type
        @dtk_version   = dtk_version
        @module        = hash['module']
        @version       = hash['version']
        @file          = hash['file']
        @path          = "#{hash['path']}/#{PuppetForge.puppet_forge_module_name(@module)}"
        @dependencies  = []
      end

      def index()
        PuppetForge.index(@namespace,@name)
      end

      def default_local_module_name
        PuppetForge.puppet_forge_module_name(@module)
      end

      def to_h
        {
          :name      => @name,
          :namespace => @namespace,
          :version   => @dtk_version,
          :type      => @type
        }
      end

    end
  end
end
