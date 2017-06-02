module DTKModule
  module DTK
    class Attributes
      module AttributeType
        def self.split(av_hash)
          ret = { component: {}, system: {}, assembly_level: {} }
          av_hash.each_pair do |qualfied_name, value| 
            type, name = parse_qualfied_name(qualfied_name)
            ret[type].merge!(name => value)
          end
          ret
        end

        private

        PREFIX_TO_TYPE = {
          'system' => :system, 
          'assembly_level' => :assembly_level
        }
        DELIM = '.'

        # returns[type, name]
        def self.parse_qualfied_name(qualfied_name)
          split = qualfied_name.to_s.split(DELIM)
          if split.size > 1 
            if type = PREFIX_TO_TYPE[split.first]
              name = split[1...split.size].join(DELIM)
              return [type, name.to_sym]
            end
          end
          # if dont match
          [:component, qualfied_name]
        end
      end

    end
  end
end
