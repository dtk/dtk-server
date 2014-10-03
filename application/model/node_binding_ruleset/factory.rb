module DTK; class NodeBindingRuleset
  class Factory
    def initialize(parent)
      @os_type = parent.os_type
      @os_identifier = parent.os_identifier
      @size = parent.size
    end
    
    def create_hash()
      hash_body = {
        :type => 'clone',
        :os_type => @os_type,
        :os_identifier=> @os_identifier
      }
      #        pntr[:rules] = Rules.add(pntr[:rules],info,ami,ec2_size)
      {ref() => hash_body}
    end
    private
    def ref()
      #TODO: stub; want normaized form so cross service providers
      "#{@os_identifier}-#{@size}"
    end
  end
end; end
=begin

      class Rules
        def self.add(rules,info,ami,ec2_size)
          new_el = {:conditions=>Conditions.new(info), :node_template=>NodeTemplate.new(info,ami,ec2_size)}
          if rules
            add_element?(rules,new_el)
          else
            [new_el]
          end
        end

      private
       def self.add_element?(rules,new_el)
         rules.each do |rule|
           if rule[:conditions].equal?(new_el[:conditions])
             Log.error("Unexpected that have matching conditions; skipping")
             return rules
           end
         end
         rules + [new_el]
       end

       class Conditions < Hash
         def initialize(info)
           replace(:type=>"ec2_image", :region=>info["region"])
         end
         def equal?(rc)
           self[:type] == rc[:type] and self[:region] == rc[:region]
         end
       end

    end
  end
end
    
=end
