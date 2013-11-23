module DTK; class ComponentDSL; class V3
  class IncrementalGenerator
    class LinkDef < IGBase::LinkDef
      def generate(aug_link_def,opts={})
        dependencies = super(aug_link_def,:no_attribute_mappings => true)
        link_defs = LinkDefsSection.new.generate(aug_link_def)
        {'dependencies' => dependencies,'link_defs' => link_defs}
      end

      def merge_fragment!(full_hash,fragment,context={})
        merge_fragment__dependencies!(full_hash,fragment['dependencies'],context)
        LinkDefsSection.new.merge_fragment!(full_hash,fragment['link_defs'],context)
        full_hash
      end

     private
      class LinkDefsSection < self
        def generate(aug_link_def)
          link_def_links = aug_link_def.required(:link_def_links)
          if link_def_links.empty?
            raise Error.new("Unexpected that link_def_links is empty")
          end
          aug_link_def[:link_def_links].inject(PossibleLinks.new) do |pl,link_def_link|
            cmp,link = choice_info(aug_link_def,ObjectWrapper.new(link_def_link))
          pl.deep_merge(cmp,link)
          end
        end

        def merge_fragment!(full_hash,fragment,context={})
          ret = full_hash
          return ret unless fragment
          component_fragment = component_fragment(full_hash,context[:component_template])
          if link_defs_fragment = component_fragment['link_defs']
            component_fragment['link_defs'] = PossibleLinks.reify(link_defs_fragment)
            fragment.each do |cmp,link|
              component_fragment['link_defs'] = component_fragment['link_defs'].deep_merge(cmp,link)
            end
          else
            component_fragment['link_defs'] = fragment
          end
          ret
        end
       private

        #returns cmp,link
        def choice_info(link_def,link_def_link)
          link = Link.new
          remote_cmp_type = link_def_link.required(:remote_component_type)
          cmp = Component.display_name_print_form(remote_cmp_type)
          location = 
            case link_def_link.required(:type)
            when 'internal' then 'local'
            when 'external' then 'remote'
            else raise new Error.new("unexpected value for type (#{link_def_link.required(:type)})")
            end
          link['location'] = location
          if dependency_name = link_def[:link_type]
            unless dependency_name == cmp
              link['dependency_name'] = dependency_name
            end
          end
          if (not link_def_link[:required].nil?) and not link_def_link[:required]
            link['required'] = false 
          end
          ams = link_def_link.object.attribute_mappings() 
          if ams and not ams.empty?
            link['attribute_mappings'] = ams.map{|am|attribute_mapping(ObjectWrapper.new(am),remote_cmp_type)}
          end
          [cmp,link]
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

      def merge_fragment__dependencies!(full_hash,fragment,context={})
        ret = full_hash
        return ret unless fragment
        component_fragment = component_fragment(full_hash,context[:component_template])
        if dependencies_fragment = component_fragment['dependencies']
          fragment.each do |key,content|
            update_depends_on_fragment!(dependencies_fragment,key,content)
          end
        else
          component_fragment['dependencies'] = [fragment]
        end
        ret
      end
    end
  end
end; end; end
