module DTK; class ComponentDSL; class V3
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

      def update_fragment!(fragment,key,content)
        fragment.each_with_index do |el,i|
          if (el.kind_of?(Hash) and el.keys.first == key) or
              (el.kind_of?(String) and el == key)
             update_matching_fragment_el!(fragment,i,key,content)
            return
          end
        end
        fragment << {key => content}
      end

      def update_matching_fragment_el!(fragment,i,key,content)
        fragment_el = fragment[i]
        if Choice.new(fragment_el).matches?(content)
          return
        end

        choices = Choices.reify(fragment_el)
        choices.update!(content)
        fragment[i] = choices.update!(content)
      end

      class Choices < Hash
        def self.reify(fragment_el)
          if fragment_el.kind_of?(Hash) and fragment_el.keys == ['choices']
            new('choices' => fragment_el['choices'].map{|choice|Choice.new(choice)})
          else
            new('choices' => [Choice.new(fragment_el)])
          end
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

       private
        def initialize(fragment_el)
          super()
          replace(fragment_el)
        end
      end

      class Choice
        def initialize(obj)
          unless obj.size == 1
            Log.error("Unexpected obj (#{obj.inspect})")
          end
          if obj.kind_of?(String)
            @key = obj
            @link = default_link()
            @is_default = true
          else #obj.kind_of?(Hash)
            @key = obj.keys.first
            @link = Link.new(obj.values.first)
          end
        end

        def matches?(link)
          @link.matches?(link)
        end
        def to_external_form()
          if @is_default
            @key
          else
            {@key => @link}
          end
        end
       private
        def default_link()
          Link.new('location' => 'local')
        end
      end
    end
  end; end
end; end; end
