# TODO: better unify with code in model/attribute special processing
module DTK
  class Node
    class NodeAttribute
      r8_nested_require('node_attribute','mixin')
      r8_nested_require('node_attribute','class_mixin')
      r8_nested_require('node_attribute','cache')
      r8_nested_require('node_attribute','default_value')

      def initialize(node)
        @node = node
      end

      def root_device_size()
        ret_value?(:root_device_size)
      end

      def cardinality(opts={})
        ret = ret_value?(:cardinality)
        (opts[:no_default] ? ret : ret||CardinalityDefault)
      end
      CardinalityDefault = 1

      def puppet_version(opts={})
        puppet_version = ret_value?(:puppet_version)
        if opts[:raise_error_if_invalid]
          raise_error_if_invalid_puppet_version(puppet_version)
        end
        puppet_version||R8::Config[:puppet][:version]
      end

      def raise_error_if_invalid_puppet_version(puppet_version)
        unless puppet_version.nil? or puppet_version.empty?
          unless RubyGemsChecker.gem_exists?('puppet', puppet_version)
           # TODO: took out because this is giving false posatives 
           # raise ErrorUsage.new("Invalid Puppet version (#{puppet_version})")
            Log.error("RubyGemsChecker.gem_exists? test fails with Puppet version (#{puppet_version})")
          end
        end
      end

      def clear_host_addresses()
        if attr = @node.get_node_attribute?('host_addresses_ipv4',:cols=>[:id,:group_id,:value_derived])
          if host_addresses = attr[:value_derived]
            if host_addresses.find{|a|!a.nil?}
              cleared_vals = host_addresses.map{|a|nil}
              attr.merge!(:value_derived => cleared_vals)
              Attribute.update_and_propagate_attributes(attr.model_handle(),[attr])
            end
          end
        end
      end
      
      TargetRefAttributes = ['host_addresses_ipv4','name','fqdn','node_components','puppet_version','root_device_size']
      TargetRefAttributeFilter = [:oneof,:display_name,TargetRefAttributes]
      NodeTemplateAttributes = ['host_addresses_ipv4','node_components','fqdn']
      AssemblyTemplateAttributeFilter = [:and] + NodeTemplateAttributes.map{|a|[:neq,:display_name,a]}
      # TODO: FieldInfo and above should be normalized
      # TODO: need to better coordinate with code in model/attribute special processing and also the
      # constants in FieldInfo
      FieldInfo = {
        :name             => {:name => :name},
        :cardinality      => {:name => :cardinality, :semantic_type => :integer},
        :root_device_size => {:name => :root_device_size, :semantic_type => :integer},
        :puppet_version   => {:name => :puppet_version}
      }

      def self.field_info(name)
        unless ret = FieldInfo[name.to_sym]
          raise Error.new("No node attribute with name (#{name})")
        end
        ret
      end
      def field_info(name)
        self.class.field_info(name)
      end

      def self.target_ref_attributes_filter()
        TargetRefAttributeFilter
      end
      def self.assembly_template_attribute_filter()
        AssemblyTemplateAttributeFilter
      end


      # for each node, one of following actions is taken
      # - if attribute does not exist, it is created with the given value
      # - if attribute exists but has vlaue differing from 'value' then it is updated
      # - otherwise no-op
      def self.create_or_set_attributes?(nodes,name,value,extra_fields={})

        node_idhs = nodes.map{|n|n.id_handle()}
        ndx_attrs = get_ndx_attributes(node_idhs,name)
        
        to_create_on_node = Array.new
        to_change_attrs = Array.new
        
        nodes.each do |node|
          if attr = ndx_attrs[node[:id]]
            existing_val = attr[:attribute_value]
            # just for simplicity no checking whether extra_fields match in 
            # test of update needed
            unless extra_fields.empty? and existing_val == value
              to_change_attrs << attr
            end
          else
            to_create_on_node << node
          end
        end
        to_change_attrs.each{|attr|attr.update(extra_fields.merge(:value_asserted => value))}
        
        unless to_create_on_node.empty?
          create_rows = to_create_on_node.map{|n|attribute_create_hash(n.id,name,value,extra_fields)}
          attr_mh = to_create_on_node.first.model_handle().create_childMH(:attribute)
          Model.create_from_rows(attr_mh,create_rows,:convert => true)
        end
      end

      def self.cache_attribute_values!(nodes,name)
        nodes_to_query = nodes.reject{|node|Cache.attr_is_set?(node,name)}
        return if nodes_to_query.empty?
        node_idhs = nodes_to_query.map{|n|n.id_handle()}
        ndx_attrs = get_ndx_attributes(node_idhs,name)

        field_info = field_info(name)
        nodes_to_query.each do |node|
          if attr = ndx_attrs[node[:id]]
            if val = attr[:attribute_value]
              Cache.set!(node,val,field_info)
            end
          end
        end
      end

     private
      # attributes indexed by node id
      def self.get_ndx_attributes(node_idhs,name)
        cols = [:id,:node_node_id,:attribute_value]
        field_info = field_info(name)
        filter =  [:eq,:display_name,field_info[:name].to_s]
        Node.get_node_level_attributes(node_idhs,:cols=>cols,:add_filter=>filter).inject(Hash.new) do |h,a|
          h.merge(a[:node_node_id] => a)
        end
      end

      def self.attribute_create_hash(node_id,name,value,extra_fields={})
        name = name.to_s
        {:ref => name,
          :display_name => name,
          :value_asserted => value,
          :node_node_id => node_id
        }.merge(extra_fields)
      end

      def ret_value?(name)
        field_info = field_info(name)
        if Cache.attr_is_set?(@node,name)
          Cache.get(@node,name)
        else
          raw_val = get_raw_value?(name)
          Cache.set!(@node,raw_val,field_info)
        end
      end

      def get_raw_value?(name)
        attr = @node.get_node_attribute?(name.to_s,:cols => [:id,:group_id,:attribute_value])
        attr && attr[:attribute_value]
      end
    end
  end
end
