module DTK
  class Assembly::Instance
    class ServiceLink
      r8_nested_require('service_link','factory')    

      def initialize(assembly_instance)
        @assembly_instance = assembly_instance
      end

      def self.delete(port_link_idhs)
        port_link_idhs = [port_link_idhs] unless port_link_idhs.kind_of?(Array)
        Model.Transaction do
          aug_attr_links = get_augmented_attribute_links(port_link_idhs)
          pp [:aug_attr_links,aug_attr_links]
          port_link_idhs.map{|port_link_idh|Model.delete_instance(port_link_idh)}
          raise ErrorUsage.new('got here')
        end
      end

      def self.print_form_hash(object,opts={})
        # set the following (some can have nil as legal value)
        service_type = base_ref = required = description = nil
        id = object[:id]
        if object.kind_of?(PortLink)
          port_link = object
          input_port = print_form_hash__port(port_link[:input_port],port_link[:input_node])
          output_port = print_form_hash__port(port_link[:output_port],port_link[:output_node])
          service_type = port_link[:input_port].link_def_name()
          if service_type != port_link[:output_port].link_def_name()
            Log.error("input and output link defs are not equal")
          end
          # TODO: confusing that input/output on port link does not reflect what is logical input/output
          if port_link[:input_port][:direction] == "input"
            base_ref = input_port
            dep_ref = output_port
          else
            base_ref = output_port
            dep_ref = input_port
          end
        elsif object.kind_of?(Port)
          port = object
          base_ref = port.display_name_print_form()
          service_type = port.link_def_name()
          if link_def = port[:link_def] 
            required = port[:required]
            description = port[:description]
          end
        else
          raise Error.new("Unexpected object type (#{object.class.to_s})")
        end
        
        ret = {
          :id => id,
          :type => service_type,
          :base_component => base_ref
        }
        ret.merge!(:dependent_component => dep_ref) if dep_ref
        ret.merge!(:required => required) if required
        ret.merge!(:description => description) if description
        ret
      end
      
     private
      def self.get_augmented_attribute_links(port_link_idhs)
        ret = Array.new
        return ret if port_link_idhs.empty?
        sp_hash = {
          :cols => [:id,:group_id,:port_link_id,:input_id,:output_id,:dangling_link_info],
          :filter => [:oneof,:port_link_id,port_link_idhs.map{|idh|idh.get_id}]
        }
        attribute_link_mh = port_link_idhs.first.createMH(:attribute_link)
        Model.get_objs(attribute_link_mh,sp_hash)
      end
      
      def self.print_form_hash__port(port,node)
        port.merge(:node=>node).display_name_print_form()
      end
    end
  end
end

