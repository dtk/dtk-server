#!/usr/bin/env ruby
require File.expand_path('common', File.dirname(__FILE__))
dtk_model_yaml_path = ARGV[0]
module DTK
  module Utility
    def self.component_doc_generator(dtk_model_yaml_path)
      server = R8Server.new('superuser', groupname: 'all')
      parsed_as_hash = server.parse_dtk_model_file(dtk_model_yaml_path)
      template = File.open(File.expand_path('component_doc_generator.md.erb', File.dirname(__FILE__))).read
      STDOUT << Erubis::Eruby.new(template).result(cmp_module: ComponentModule.new(parsed_as_hash))
    end
    class Top < Hash
      def initialize(hash)
        super()
        replace(hash)
      end
    end
    class ComponentModule < Top
      def name
        self['module']
      end

      def dsl_version
        self['dsl_version']
      end

      def type
        ret = self['module_type']
        ret && ret.gsub(/_module/, '')
      end

      def components
        ret = []
        (self['components'] || {}).each_pair do |cmp_name, cmp_info|
          ret << Component.new(cmp_name, cmp_info)
        end
        ret
      end
    end

    class Component < Top
      def initialize(cmp_name, cmp_info)
        super({ 'name' => cmp_name }.merge(cmp_info))
      end

      def name
        self['name']
      end

      def attributes
        ret = []
        (self['attributes'] || {}).each_pair do |attr_name, attr_info|
          ret << Attribute.new(attr_name, attr_info)
        end
        ret
      end
    end

    class Attribute < Top
      def initialize(attr_name, attr_info)
        super({ 'name' => attr_name }.merge(attr_info))
      end

      def name
        self['name']
      end

      def type
        self['type']
      end
      #TODO: looks like Erubis bug when method called 'default' used
      def default_value
        self['default']
      end

      def description
        self['description']
      end
    end
  end
end

unless dtk_model_yaml_path
  fail 'Path to model.dtk.yaml file must be given'
end
unless File.exists?(dtk_model_yaml_path)
  fail "File (#{dtk_model_yaml_path}) does not exist"
end
DTK::Utility.component_doc_generator(dtk_model_yaml_path)
