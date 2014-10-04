module DTK; class NodeBindingRuleset
  class Factory
    def initialize(top_factory)
      @top_factory = top_factory
      @os_type = top_factory.os_type
      @os_identifier = top_factory.os_identifier
      @size = top_factory.size
    end

    def create_hash()
      hash_body = {
        :type => 'clone',
        :os_type => @os_type,
        :os_identifier=> @os_identifier,
        :rules => Rules.create(@top_factory)
      }
      {ref() => hash_body}
    end

    def ref()
      #TODO: stub; may want normaized of size form so abstracted from iaas
      "#{@os_identifier}-#{@size}"
    end

    class Rules
      def self.create(top_factory)
        target = top_factory.target
        type = Node::Template.image_type(target)
        region = target.iaas_properties.hash[:region]
        el = {
          :conditions => conditions(type,region),
          :node_template => node_template(top_factory,type,region)
        }
        [el]
      end

      def self.conditions(type,region)
        {
          :type => type,
          :region => region
        }
      end

      def self.node_template(top_factory,type,region)
        {
          :type => type,
          :region=> region,
          :image_id => top_factory.image_id,
          :size => top_factory.size
        }
      end
    end
  end
end; end
    

