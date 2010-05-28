module XYZ
  class NetworkPartition < Model
    set_relation_name(:network,:partition)
    class << self
      def up()
        many_to_one :library,:deployment,:project
      end
    end
  end

  class NetworkGateway < Model
    set_relation_name(:network,:gateway)
    class << self
      def up()
        foreign_key :network_partition1_id, :network_partition, FK_CASCADE_OPT
        foreign_key :network_partition2_id, :network_partition, FK_CASCADE_OPT
        many_to_one :library,:deployment,:project
      end
    end
  end
end