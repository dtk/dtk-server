module DTK; class ComponentDSL; class V3
  class IncrementalGenerator
    class LinkDef < IGBase::LinkDef
      r8_nested_require('link_def','dependencies_section')
      r8_nested_require('link_def','link_defs_section')
      def generate(aug_link_def,opts={})
        dependencies = DependenciesSection.new(aug_link_def).generate()
        link_defs = LinkDefsSection.new(aug_link_def).generate()
        {'dependencies' => dependencies,'link_defs' => link_defs}
      end

      def merge_fragment!(full_hash,fragment,context={})
        DependenciesSection.new.merge_fragment!(full_hash,fragment['dependencies'],context)
        LinkDefsSection.new.merge_fragment!(full_hash,fragment['link_defs'],context)
        full_hash
      end
     private
      def initialize(aug_link_def=nil)
        @aug_link_def = aug_link_def
      end

      #PossibleLinks has form {cmp1 => LINK(s), cmp2 => LINK(s), ..}
      # where LINK(s) ::= LINK | [LINK,LINK,..]
      class PossibleLinks < Hash
        def deep_merge(cmp,link)
          new_cmp_val = 
            if target_links = self[cmp]
              link.merge_into!(target_links.kind_of?(Array) ? target_links : [target_links])
            else
              link
            end
          merge(cmp => new_cmp_val)
        end
        
        def self.reify(possible_links)
          possible_links.inject(PossibleLinks.new()) do |h,(cmp,v)|
            h.merge(cmp => v.kind_of?(Array) ? v.map{|el|Link.new(el)} : Link.new(v))
          end
        end
      end
      
      class Link < PrettyPrintHash
        def merge_into!(links)
          ret = links
          if match = links.find{|link|match?(link)}
            if am = self['attribute_mappings']
              match['attribute_mappings'] = am
            end
          else
            ret << self
          end
            ret
        end
        
        def initialize(seed_hash={})
          super()
          merge!(seed_hash)
        end

       private
        def match?(link)
          pruned_keys = keys-['attribute_mappings']
          pruned_link_keys = link.keys-['attribute_mappings']
          if Aux.equal_sets(pruned_keys,pruned_link_keys)
            !pruned_keys.find{|k|link[k] != self[k]}
          else
            Log.error("Unexpected that keys dont match (#{keys.join(',')}) and (#{link.keys.join(',')})")
            false
          end
        end
      end
    end
  end
end; end; end
