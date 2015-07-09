# TODO: will move get methods that will not be deprecating to here or some file underneath a file directory
module DTK; class Attribute
  module GetMethod
    module Mixin
      def get_attribute_def
        update_object!(:id,:display_name,:value_asserted,:required,:external_ref,:dyanmic,:data_type,:semantic_type,:semantic_type_summary,:config_agent_type)
        ret = {}
        [:id,:required,:dyanmic].each{|k|ret[k] = self[k] if self[k]}
        ret[:field_name] = self[:display_name]

        # put in optional key that inidcates implementation attribute
        impl_attr = ret_implementation_attribute_name_and_type()
        # default is that implementation attribute name same as r8 attribute name; so omit if default
        unless self[:display_name] == impl_attr[:name]
          case impl_attr[:type].to_sym
          when :puppet then ret.merge!(puppet_attribute_name: impl_attr[:name])
          when :chef then ret.merge!(chef_attribute_name: impl_attr[:name])
          end
        end
        ret[:datatype] = ret_datatype()

        if default_info = ret_default_info()
          ret[:default_info] = default_info
        end
        ret
      end

      def get_constraints!(opts={})
        Log.error('opts not implemented yet') unless opts.empty?
        dependency_list = get_objects_col_from_sp_hash({columns: [:dependencies]},:dependencies)
        Constraints.new(:or,dependency_list.map{|dep|Constraint.create(dep)})
      end

      def get_node(opts={})
        unless node_node_id = get_field?(:node_node_id)
          raise Error.new('get_node should not be called if attribute not on a node')
        end
        sp_hash = {
          cols: opts[:cols]||[:id,:group_id,:display_name],
          filter: [:eq,:id,node_node_id]
        }
        ret = Node.get_obj(model_handle(:node),sp_hash)
        if subclass_model_name = opts[:subclass_model_name]
        ret = ret.create_subclass_obj(subclass_model_name)
        end
        ret
      end

      def self.get_port_info(id_handles)
        get_objects_in_set_from_sp_hash(id_handles,{cols: [:port_info]},keep_ref_cols: true)
      end

      def get_service_node_group(opts={})
        get_node(opts.merge(subclass_model_name: :service_node_group))
      end

      private

      def ret_implementation_attribute_name_and_type
        config_agent = ConfigAgent.load(self[:config_agent_type])
        config_agent && config_agent.ret_attribute_name_and_type(self)
      end
    end

    module ClassMixin
      def get_attribute_from_identifier(identifier, mh, cmp_id)
        valid_attribute = nil
        if identifier.to_s =~ /^[0-9]+$/
          sp_hash = {
            cols: Attribute.common_columns(),
            filter: [:eq,:id,identifier]
          }

          valid_attribute = Model.get_obj(mh,sp_hash)
          raise ErrorUsage.new("Illegal identifier '#{identifier}' for component-module attribute") unless valid_attribute
        else
          # extracting component and attribute name from identifier
          # e.g. cmp[dtk_addons::rspec2db]/user => component_name = dtk_addons::rspec2db, attribute_name = user
          match_from_identifier = identifier.match(/.+\[(.*)\]\/(.*)/)

          if match_from_identifier
            param_cmp_name  = match_from_identifier[1].gsub(/::/,'__')
            param_attr_name = match_from_identifier[2].gsub(/::/,'__')
          end

          raise ErrorUsage.new("Illegal identifier '#{identifier}' for component-module attribute") unless param_attr_name && param_cmp_name

          sp_hash = {
            # component_module_parent will return more info about attribute (component it belongs to and module branch which we can get component_module_id from)
            cols: common_columns + [:component_module_parent],
            filter: [:eq, :display_name, param_attr_name]
          }
          matching_attributes = Model.get_objs(mh,sp_hash)

          # every component attribute has external_ref field with info ({"type":"puppet_attribute","path":"node[logrotate__rule][copytruncate]"})
          # using external_ref[:path] to extract component_name (logrotate__rule) and attribute_name (copytruncate)
          # and compare to data that user have sent as params
          matching_attributes.each do |m_attr|
            if (external_ref = m_attr[:external_ref]) && (path = m_attr[:external_ref][:path])
              match = path.match(/.+\[(.*)\]\[(.*)\]/)
              cmp_name, attr_name = match[1], match[2] if match

              if module_branch = m_attr[:module_branch]
                valid_attribute = m_attr if param_cmp_name.eql?(cmp_name) && param_attr_name.eql?(attr_name) && module_branch[:component_id].to_s.eql?(cmp_id)
            end
              break if valid_attribute
            end
          end

          raise ErrorUsage.new("Illegal identifier '#{identifier}' for component-module attribute") unless valid_attribute
        end

        valid_attribute
      end

      def get_augmented(model_handle,filter)
        ret = []
        sp_hash = {
          cols: common_columns + [:node_component_info],
          filter: filter
        }
        attrs = get_objs(model_handle,sp_hash)
        return ret if attrs.empty?
        attrs.each do |r|
          r.delete(:component) if r[:component].nil? #get rid of nil :component cols

          if node = r.delete(:direct_node)||r.delete(:component_node)
            r.merge!(node: node)
          end
        end
        attrs
      end
    end
  end
end; end
