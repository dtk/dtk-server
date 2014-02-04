module DTK
  module ComponentTitle
    def self.print_form_with_title(component_name,title)
      "#{component_name}[#{title.to_s}]"
    end
    
    #this is for field display_name
    def self.display_name_with_title(component_type,title)
      "#{component_type}[#{title}]"
    end
    def self.display_name_with_title?(component_type,title=nil)
      title ? display_name_with_title(component_type,title) : component_type
    end

    def self.ref_with_title(component_type,title)
      "#{component_type}--#{title}"
    end

    # if opts has :node_prefix, returns [node_name,component_type,title]
    # else returns [component_type,title]
    # if ilegal form, nil will be returned
    # in all cases title could be nil
    def self.parse_component_user_friendly_name(user_friendly_name,opts={})
      node_name = component_type = title = nil
      cmp_display_name = Component.display_name_from_user_friendly_name(user_friendly_name)
      cmp_node_part,title = parse_component_display_name(cmp_display_name)

      if opts[:node_prefix]
        if cmp_node_part  =~ SplitNodeComponentType
          node_name,component_type = [$1,$2]
        end
        [node_name,component_type,title]
      else
        component_type = cmp_node_part
        [component_type,title]
      end
    end
    SplitNodeComponentType = /(^[^\/]+)\/([^\/]+$)/

    #returns [component_type,title]; title could be nil if cmp_display_name has node prefix component_type will have this
    def self.parse_component_display_name(cmp_display_name)
      if cmp_display_name =~ ComponentTitleRegex
        [$1,$2]
      else
        [cmp_display_name,nil]
      end
    end
    def self.parse_title?(cmp_display_name)
      if cmp_display_name =~ ComponentTitleRegex
        $2
      end
    end
    ComponentTitleRegex = /(^.+)\[(.+)\]$/


    #component can be a hash or object
    def self.title?(component)
      return nil unless component #convience so dont have to check argument being passed is nil
      display_name = component[:display_name] || (component.kind_of?(Component) && component.get_field?(:display_name))
      unless display_name
        raise Error.new("Parameter (component) should have :display_name field")
      end
      component_type,title = parse_component_display_name(display_name)
      title
    end

  end
end
