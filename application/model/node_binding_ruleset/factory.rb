module DTK; class NodeBindingRuleset
  class Factory
    def initialize(top_factory)
      @top_factory = top_factory
      @os_type = top_factory.os_type
      @os_identifier = top_factory.os_identifier
      @size = top_factory.size

pp matching_node_binding_ruleset()
    end

    def matches_existing_item?()
      if matching_nbrs = matching_nbrs_object?()
        matching_nbrs.has_size(@size)
      end
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

   private
    def matching_node_binding_ruleset()
      if @nbrs_calculated
        @matching_node_binding_ruleset 
      else
        @nbrs_calculated = true
        sp_hash = {
          :cols => NodeBindingRuleset.common_columns(),
          :filter => [:eq,:ref,ref()]
        }
        @matching_node_binding_ruleset = Model.get_obj(model_handle(),sp_hash)
      end
    end

    def model_handle()
      @model_handle ||= @top_factory.target.model_handle(:node_binding_ruleset)
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
    

