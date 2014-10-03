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
      #        pntr[:rules] = Rules.add(pntr[:rules],info,ami,ec2_size)
      {ref() => hash_body}
    end

   private
    def ref()
      #TODO: stub; may want normaized of size form so abstracted from iaas
      "#{@os_identifier}-#{@size}"
    end

    class Rules
      def self.create(top_factory)
        el = {
          :conditions=>Conditions.new(top_factory), 
#          :node_template=>NodeTemplate.new(top_factory)
        }
        [el]
      end

      class Conditions < Hash
        attr_reader :iaas_properties
        def initialize(top_factory)
          target = top_factory.target
          iaas_properties = target.iaas_properties
          hash = {
            :type => Node::Template.image_type(target),
            :region => iaas_properties.hash[:region]
          }
          replace(hash)
        end

      end
    end
  end
end; end
    

