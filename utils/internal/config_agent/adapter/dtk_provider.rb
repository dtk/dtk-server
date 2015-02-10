module DTK; class ConfigAgent; module Adapter
#  class DtkProvider < ConfigAgent
  require File.expand_path('puppet', File.dirname(__FILE__))
  class DtkProvider < ConfigAgent::Adapter::Puppet
    def ret_msg_content(config_node,opts={})
      cmps_with_attrs = components_with_attributes(config_node)
      assembly_attrs = assembly_attributes(config_node)
      puppet_manifests = NodeManifest.new(config_node).generate(cmps_with_attrs,assembly_attrs)
      ret = {
        :components_with_attributes => cmps_with_attrs, 
      :node_manifest => puppet_manifests, 
        :inter_node_stage => config_node.inter_node_stage()
      }
      if assembly = opts[:assembly]
        ret.merge!(:service_id => assembly.id(), :service_name => assembly.get_field?(:display_name))
      end
      ret
    end
  end
end; end; end
