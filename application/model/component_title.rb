module DTK
  module ComponentTitle
    def self.print_form_with_title(component_name,title)
      "#{component_name}[#{title.to_s}]"
    end
    
    #this is for field display_name
    def self.display_name_with_title(component_type,title)
      "#{component_type}[#{title}]"
    end

    def self.ref_with_title(component_type,title)
      "#{component_type}--#{title}"
    end

    #component can be a hash or object
    def self.title?(component)
      return nil unless component #convience so dont have to check argument being passed is nil
      display_name = component[:display_name] || (component.kind_of?(Component) && component.get_field?(:display_name))
      unless display_name
        raise Error.new("Parameter (component) should have :display_name field")
      end
      if display_name =~ /^.+\[(.+)\]$/
        $1
      end
    end
  end
end
