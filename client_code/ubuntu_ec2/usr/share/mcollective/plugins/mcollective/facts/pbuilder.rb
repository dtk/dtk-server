require 'ohai'

module MCollective
  module Facts
    # A factsource for pbuilder
    class Pbuilder < Base
      #TODO: stub that right now just returns pbuilderid
      @@facts = Hash.new

      def get_facts
        if @@facts["pbuilderid"].nil?
          o = Ohai::System.new
          #TODO: just run selected ones
          o.all_plugins
          @@facts["pbuilderid"] = o[:ec2][:instance_id]
        end
        @@facts 
      end
    end
  end
end
