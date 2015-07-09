module DTK
  class DNS
    class R8 < self
      def initialize(node)
        @node = node
      end
      def self.generate_node_assignment?(node)
        new(node).generate_node_assignment?()
      end

      def generate_node_assignment?
        unless aug_node = aug_node_when_dns_enabled?()
          return nil
        end

        unless domain = ::R8::Config[:dns][:r8][:domain]
          fail Error.new('Server config variable (dns.r8.domain) has not been set')
        end

        unless tenant = ::R8::Config[:dns][:r8][:tenant_name]
          fail Error.new('Server config variable (dns.r8.tenant_name) has not been set')
        end

        dns_info = {
          assembly: aug_node[:assembly][:display_name],
          node: aug_node[:display_name],
          user: CurrentSession.get_username(),
          tenant: tenant,
          domain: domain
        }
        Assignment.new(dns_address(dns_info))
      end

      private

      def dns_address(info)
        # TODO: should validate ::R8::Config[:dns][:r8][:format]
        format = ::R8::Config[:dns][:r8][:format] || DefaultFormat
        ret = format.dup
        [:node, :assembly, :user, :tenant, :domain].each do |part|
          ret.gsub!(Regexp.new("\\${#{part}}"), info[part])
        end
        ret
      end
      DefaultFormat = '${node}.${assembly}.${user}.${tenant}.${domain}'

      def aug_node_when_dns_enabled?
        if aug_node = get_aug_node_when_dns_info?()
          # check it has a true value; to be robust looking for a string or a Boolean
          if val = (aug_node[:dns_enabled_attribute] || {})[:attribute_value]
            if val.is_a?(String)
              aug_node if (val =~ /^(t|T)/)
            else
              aug_node if val.is_a?(TrueClass)
            end
          end
        end
      end

      def get_aug_node_when_dns_info?
        sp_hash = {
          cols: [:dns_enabled_on_node, :id, :group_id, :display_name]
        }
        # checking for multiple rows to handle case where multiple dns attributes given
        aug_nodes = @node.get_objs(sp_hash)

        if aug_nodes.empty?
          # This can wil be empty only if no assembly tied to node
          # This is expected if node is target ref
          # TODO: dont think dns enabledment works with node groups
          @node.update_obj!(:display_name, :type)
          unless @node[:type] == 'target_ref'
            Log.error_pp(['unexpected that that following node not tied to assembly', @node])
          end
        end

        if ret = select_aug_node?(aug_nodes)
          return ret
        end

        sp_hash = {
          cols: [:dns_enabled_on_assembly, :id, :group_id, :display_name]
        }

        aug_nodes = @node.get_objs(sp_hash)
        select_aug_node?(aug_nodes)
      end

      def select_aug_node?(aug_nodes)
        aug_nodes.reject { |n| n[:dns_enabled_attribute].nil? }.sort do |n1, n2|
          DNS.attr_rank(n2[:dns_enabled_attribute]) <=> DNS.attr_rank(n1[:dns_enabled_attribute])
        end.first
      end

      def attr_rank(attr)
        ret = LowestRank
        if attr_name = (attr || {})[:display_name]
          if rank = RankPos[attr_name]
            ret = rank
          end
        end
        ret
      end

      AttributeKeys = Node::DNS::AttributeKeys
      # Assumes that AttributeKeys has been defined already
      RankPos = AttributeKeys.inject({}) do|h, ak|
        h.merge(ak => AttributeKeys.index(ak))
      end
      LowestRank = AttributeKeys.size
    end
  end
end
