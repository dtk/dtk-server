module DTK; class ModuleDSL; class V3
  class IncrementalGenerator; class LinkDef
    class DependenciesSection < self
      def generate()
        ref = @aug_link_def.required(:link_type)
        link_def_links = @aug_link_def.required(:link_def_links)
        if link_def_links.empty?
          raise Error.new("Unexpected that link_def_links is empty")
        end
        opts_choice = Hash.new
        if single_choice = (link_def_links.size == 1) 
          opts_choice.merge!(:omit_component_ref => ref)
        end
        possible_links = @aug_link_def[:link_def_links].map do |link_def_link|
          choice_info(ObjectWrapper.new(link_def_link),opts_choice)
        end
        content = (single_choice ? possible_links.first : {'choices' => possible_links})
        {ref => content}
      end

      def merge_fragment!(full_hash,fragment,context={})
        ret = full_hash
        return ret unless fragment
        component_fragment = component_fragment(full_hash,context[:component_template])
        if dependencies_fragment = component_fragment['dependencies']
          unless dependencies_fragment.kind_of?(Array)
            dependencies_fragment = component_fragment['dependencies'] = [dependencies_fragment]
          end
          fragment.each do |key,content|
            update_fragment!(dependencies_fragment,key,content)
          end
        else
          component_fragment['dependencies'] = [fragment]
        end
        ret
      end

     private
      def choice_info(link_def_link,opts={})
        ret = Link.new
        cmp_ref = link_component(link_def_link)
        unless opts[:omit_component_ref] == cmp_ref
          ret['component'] = cmp_ref
        end
        ret['location'] = link_location(link_def_link)
        if link_required_is_false?(link_def_link)
          ret['required'] = false 
        end
        ret
      end

      def update_fragment!(fragment,key,link)
        fragment.each_with_index do |fragment_el,i|
          if key == Dependency.key(fragment_el)
             update_matching_fragment_el!(fragment,i,key,link)
            return
          end
        end
        fragment << {key => link}
      end

      def update_matching_fragment_el!(fragment,i,key,link)
        fragment_el = fragment[i]
        if Dependency.new(fragment_el).matches?(link)
          return
        end

        choices = Choices.reify(key,Dependency.link(fragment_el))
        choices.update!(link)
        fragment[i] = choices.external_form()
      end

      class Choices < Hash
        def self.reify(key,fragment_link)
          choices = 
            if fragment_link.keys == ['choices']
              fragment_link['choices'].map do |choice|
                 Dependency.new(choice.kind_of?(String) ? choice : {key => choice})
              end   
            else
              [Dependency.new(key => fragment_link)]
            end
          new(key,'choices' => choices)
        end

        def update!(link)
          ret = self
          ret['choices'].each_with_index do |choice,i|
            if choice.matches?(link)
              ret['choices'][i] = link
              return ret
            end
          end
          ret['choices'] << link
          ret
        end
        def external_form()
          ext_form_choices = self['choices'].map do |r|
            r.kind_of?(Dependency) ? r.external_form() : r
          end
          {@key => self.merge('choices' => ext_form_choices)}
        end
       private
        def initialize(key,fragment_link)
          super()
          @key = key
          replace(fragment_link)
        end
      end

      class Dependency
        def initialize(obj)
          @key,@link,@is_default = self.class.key__link__is_default(obj)
        end

        def self.key(obj)
          key__link__is_default(obj)[0]
        end
        def self.link(obj)
          key__link__is_default(obj)[1]
        end
        
        def matches?(link)
          @link.matches?(link)
        end
        def external_form()
          if @is_default
            @key
          else
            @link
          end
        end
       private
        def self.key__link__is_default(obj)
          if obj.kind_of?(String)
            [obj,default_link(),true]
          else #obj.kind_of?(Hash)
            [obj.keys.first,Link.new(obj.values.first),false]
          end
        end

        def default_link()
          Link.new('location' => 'local')
        end
      end
    end
  end; end
end; end; end
