module DTK; class ComponentDSL; class V2
  class IncrementalGenerator
    def self.generate(aug_object)
      klass(aug_object).new().generate(ObjectWrapper.new(aug_object))
    end

    def self.merge_fragment_into_full_hash!(full_hash,object_class,fragment,context={})
      klass(object_class).new().merge_fragment!(full_hash,fragment,context)
      full_hash
    end

   private
    def self.klass(object_or_class)
      klass = (object_or_class.kind_of?(Class) ? object_or_class : object_or_class.class)
      class_last_part = klass.to_s.split('::').last
      ret = nil
      begin 
        ret = const_get class_last_part
       rescue
        raise Error.new("Generation of type (#{class_last_part}) not treated")
      end
      ret
    end

    class ObjectWrapper
      attr_reader :object
      def initialize(object)
        @object = object
      end
      def required(key)
        ret = @object[key]
        if ret.nil?
          raise Error.new("Expected that object of type (#{@object}) has non null key (#{key})")
        end
        ret
      end
      def [](key)
        @object[key]
      end
    end

    class Component < self
      def self.display_name_print_form(cmp_type)
        ::DTK::Component.display_name_print_form(cmp_type)
      end
      def self.get_fragment(full_hash,cmp_type)
        unless ret = (full_hash['components']||{})[hash_index(cmp_type)]
          raise Error.new("Cannot find component (#{display_name_print_form(cmp_type)})")
        end
        ret
      end

     private
      def self.hash_index(cmp_type)
        ::DTK::Component.display_name_print_form(cmp_type,:no_module_name => true)
      end
    end

    class LinkDef < self
      def generate(aug_link_def)
        ref = aug_link_def.required(:link_type)
        link_def_links = aug_link_def.required(:link_def_links)
        if link_def_links.empty?
          raise Error.new("Unexpected that link_def_links is empty")
        end
        possible_links = aug_link_def[:link_def_links].map do |link_def_link|
          choice_info(aug_link_def,ObjectWrapper.new(link_def_link))
        end
        content = 
          if possible_links.size == 1
            possible_links.first
          else
            {'choices' => possible_links}
          end
        {ref => content}
      end

      def merge_fragment!(full_hash,fragment,context={})
        component_fragment = component_fragment(full_hash,context[:component_template])
        if depends_on_fragment = component_fragment['depends_on']
          fragment.each do |key,content|
            update_depends_on_fragment!(depends_on_fragment,key,content)
          end
        else
          component_fragment['depends_on'] = [fragment]
        end
        full_hash
      end

     private
      def component_fragment(full_hash,component_template)
        unless component_type = component_template && component_template.get_field?(:component_type)
          raise Error.new("The method merge_fragment needs the context :component_template")
        end
        Component.get_fragment(full_hash,component_type)
      end

      def update_depends_on_fragment!(depends_on_fragment,key,content)
        depends_on_fragment.each_with_index do |depends_on_el,i|
          if (depends_on_el.kind_of?(Hash) and depends_on_el.keys.first == key) or
              (depends_on_el.kind_of?(String) and depends_on_el == key)
            depends_on_fragment[i] = {key => content}
            return
          end
        end
        depends_on_fragment << {key => content}
      end

      def choice_info(link_def,link_def_link)
        ret = PrettyPrintHash.new
        remote_cmp_type = link_def_link.required(:remote_component_type)
        ret['component'] = Component.display_name_print_form(remote_cmp_type)
        location = 
          case link_def_link.required(:type)
            when 'internal' then 'local'
            when 'external' then 'remote'
            else raise new Error.new("unexpected value for type (#{link_def_link.required(:type)})")
          end
        ret['location'] = location
        if (not link_def_link[:required].nil?) and not link_def_link[:required]
          ret['required'] = false 
        end
        ams = link_def_link.object.attribute_mappings() 
        if ams and not ams.empty?
          ret['attribute_mappings'] = ams.map{|am|attribute_mapping(ObjectWrapper.new(am),remote_cmp_type)}
        end
        ret
      end
      
      def attribute_mapping(am,remote_cmp_type)
        input_attr,input_is_remote = mapping_attribute(:input,am,remote_cmp_type)
        output_attr,output_is_remote = mapping_attribute(:output,am,remote_cmp_type)
        if (!input_is_remote) and (!output_is_remote)
          raise Error.new("Cannot determine attribute mapping direction; both do not match remote component type")
        elsif input_is_remote and output_is_remote
          raise Error.new("Cannot determine attribute mapping direction; both match remote component type")
        elsif (!input_is_remote) and output_is_remote
          "$#{output_attr} -> #{input_attr}"
        else #input_is_remote and (!output_is_remote)
          "#{input_attr} <- $#{output_attr}"
        end
      end

      def mapping_attribute(input_or_output,am,remote_cmp_type)
        var = ObjectWrapper.new(am.required(input_or_output))
        case var.required(:type)
          when 'component_attribute' then mapping_attribute__component_type(var,remote_cmp_type)
          when 'node_attribute' then mapping_attribute__node_type(var)
          else raise Error.new("Unexpected mapping-attribute type (#{var.required(:var)})")
        end  
      end

      def mapping_attribute__component_type(var,remote_cmp_type)
        split = var.required(:term_index).split('.')
        unless split.size == 2
          raise Error.new("Not yet implemented: treating component mapping-attribute of form (#{var.required(:term_index)})")
        end
        attr = var.required(:attribute_name)
        [attr,var.required(:component_type) == remote_cmp_type]
      end

      def mapping_attribute__node_type(var)
        if ['host_address','host_addresses_ipv4'].include?(var.required(:attribute_name))
          attr = 'node.host_address'
          [attr,var.required(:node_name) == 'remote']
        else
          raise Error.new("Not yet implemented: treating node mapping-attribute of form (#{var.required(:term_index)})")
        end
      end
    end
  end
end; end; end
