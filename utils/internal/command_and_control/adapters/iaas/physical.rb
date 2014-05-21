module DTK
  module CommandAndControlAdapter
    class Physical < CommandAndControlIAAS
      def self.destroy_node?(node,opts={})
        true #vacuously succeeds
      end
      def self.check_security_group_and_key_pair(iaas_credentials)
        {}
      end
    end
  end
end
