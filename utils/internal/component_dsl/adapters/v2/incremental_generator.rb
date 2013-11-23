module DTK; class ComponentDSL; class V2
  class IncrementalGenerator < ComponentDSL::IncrementalGenerator
   private
    def component()
      Component
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

    class Attribute < self
      def generate(attr)
        #TODO: treat default and external_ref
        attr.object.update_object!(:display_name,:description,:data_type,:semantic_type,:required,:dynamic,:external_ref)
        ref = attr.required(:display_name)
        content = PrettyPrintHash.new
        set?(:description,content,attr)
        type = type(attr[:data_type],attr[:semantic_type])
        content['type'] = type if type
        content['required'] = true if attr[:required]
        content['dynamic'] = true if attr[:dynamic]
        {ref => content}
      end

      def merge_fragment!(full_hash,fragment,context={})
        component_fragment = component_fragment(full_hash,context[:component_template])
        if attributes_fragment = component_fragment['attributes']
          fragment.each do |key,content|
            update_attributes_fragment!(attributes_fragment,key,content)
          end
        else
          component_fragment['attributes'] = fragment
        end
        full_hash
      end

     private
      def type(data_type,semantic_type)
        ret = data_type
        if semantic_type
          unless semantic_type.kind_of?(Hash) and semantic_type.size == 1 and semantic_type.keys.first == ":array"
            Log.error("Ignoring because unexpected semantic type (#{semantic_type})")
          else
            ret = "array(#{semantic_type.values.first})"
          end
        end
        ret||'string'
      end

      def update_attributes_fragment!(attributes_fragment,key,content)
        (attributes_fragment[key] ||= Hash.new).merge!(content)
      end
    end

    class LinkDef < self
      def generate(aug_link_def,opts={})
        ref = aug_link_def.required(:link_type)
        link_def_links = aug_link_def.required(:link_def_links)
        if link_def_links.empty?
          raise Error.new("Unexpected that link_def_links is empty")
        end
        opts_choice = opts
        if single_choice = (link_def_links.size == 1) 
          opts_choice = opts.merge(:omit_component_ref => ref)
        end
        possible_links = aug_link_def[:link_def_links].map do |link_def_link|
          choice_info(aug_link_def,ObjectWrapper.new(link_def_link),opts_choice)
        end
        content = (single_choice ? possible_links.first : {'choices' => possible_links})
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

      def choice_info(link_def,link_def_link,opts={})
        ret = PrettyPrintHash.new
        remote_cmp_type = link_def_link.required(:remote_component_type)
        cmp_ref = Component.display_name_print_form(remote_cmp_type)
        unless opts[:omit_component_ref] == cmp_ref
          ret['component'] = cmp_ref
        end
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
        unless opts[:no_attribute_mappings]
          ams = link_def_link.object.attribute_mappings() 
          if ams and not ams.empty?
            ret['attribute_mappings'] = ams.map{|am|attribute_mapping(ObjectWrapper.new(am),remote_cmp_type)}
          end
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
