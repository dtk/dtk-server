module DTK; class Node
  class Template
    class Factory < self
      def self.create(target,node_template_name,image_id,opts={})
        raise_error_if_invalid_image(image_id,target)
        raise_error_if_invalid_os(opts[:operating_system])
        size_array = raise_error_if_invalid_size_array(opts[:size_array])
        factory_array = size_array.map{|size|new(target,node_template_name,image_id,size,opts)}
        node_templates = factory_array.inject(Hash.new){|h,r|h.merge(r.node_template())}

        node_binding_rulesets = factory_array.inject(Hash.new){|h,r|h.merge(r.node_binding_ruleset())}

pp node_binding_rulesets
=begin
        hash_content = {
          :node=> node_templates, 
          :node_binding_ruleset => node_binding_rulesets
        }
        Model.import_objects_from_hash(public_library_idh,hash_content)
=end
        nil
      end

      attr_reader :target,:image_id,:os_identifier,:os_type,:size

      def initialize(target,os_identifier,image_id,size,opts={})
        @target = target
        @image_id = image_id
        @os_identifier = os_identifier
        @os_type = opts[:operating_system]
        @size = size
      end

      def node_binding_ruleset()
        NodeBindingRuleset::Factory.new(self).create_hash()
      end

      def node_template()
        hash_body = {
          :os_type => @os_type,
          :os_identifier => @os_identifier, 
          :type => 'image',
          :display_name => node_template_display_name(),
          :external_ref =>{
            :image_id => @image_id, 
            :type => node_template_type(),
            :size => @size
          },
          :attribute => {
            'host_addresses_ipv4' => NodeAttribute::DefaultValue.host_addresses_ipv4(),
            'fqdn' => NodeAttribute::DefaultValue.fqdn(),
            'node_components' => NodeAttribute::DefaultValue.node_components()
          },
          :node_interface => {'eth0' => {:type => 'ethernet', :display_name => 'eth0'}}
        }
        #if node_binding_rs_id = node_info_binding_ruleset_id(info,opts)
       # ret["*node_binding_rs_id"] =  node_binding_rs_id
        # end
        {node_template_ref() => hash_body}
      end

     private
      def self.raise_error_if_invalid_image(image_id,target)
        CommandAndControl.raise_error_if_invalid_image?(image_id,target)
        image_id
      end
      def self.raise_error_if_invalid_os(os)
          if os.nil?
            raise ErrorUsage.new("Operating system must be given")
          end
        os #TODO: stub
      end
      def self.raise_error_if_invalid_size_array(size_array)
        size_array ||= ['t1.micro'] #TODO: stub
        if size_array.nil?
          raise ErrorUsage.new("One or more image sizes must be given")
        end
        # size_array.each{|image_size|CommandAndControl.raise_error_if_invalid_image_size(image_size,target)}
        size_array
      end

      def node_template_ref()
        "#{@image_id}-#{@size}"
      end
      def node_template_display_name()
        "#{@os_identifier} #{@size}"
      end
      def node_template_type()
        Template.image_type(@target)
      end
    end
  end
end; end
