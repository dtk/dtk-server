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

    ComponentTitleRegex = /(^.+)\[(.+)\]$/
    #returns [component_type,title]
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
