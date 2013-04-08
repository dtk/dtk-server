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

    def self.title?(component)
      display_name = component.get_field?(:display_name)
      if display_name =~ /^.+\[(.+)\]$/
        $1
      end
    end
  end
end
