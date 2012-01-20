require  File.expand_path('link_def/context', File.dirname(__FILE__))
module XYZ
  class LinkDefLink < Model
    include LinkDefParseSerializedForm
    def self.create_from_serialized_form(link_def_idh,possible_links)
      rows = parse_possible_links(possible_links)
      link_def_id = link_def_idh.get_id()
      rows.each_with_index do |r,i|
        r[:position] = i+1
        r[:link_def_id] = link_def_id
      end
      create_from_rows(model_handle,rows)
    end

    def process(parent_idh,components,port_link_idh=nil)
      link_defs_info = components.map{|cmp| {:component => cmp}}
      context = get_context(link_defs_info)
      on_create_events.each{|ev|ev.process!(context)}
      #ret_links returns nil only if error such as not being able to find input_id or output_id
      links = attribute_mappings.map{|am|am.ret_link(context)}.compact
      return if links.empty?
      if port_link_idh
        port_link_id = port_link_idh.get_id()
        links.each{|link|link[:port_link_id] = port_link_id}
      end
      AttributeLink.create_attribute_links(parent_idh,links)
    end

    def attribute_mappings()
      self[:attribute_mappings] ||= (self[:content][:attribute_mappings]||[]).map{|am|AttributeMapping.new(am)}
    end

    def on_create_events()
      self[:on_create_events]||= ((self[:content][:events]||{})[:on_create]||[]).map{|ev|Event.create(ev,self)}
    end

    #TODO: this is making too many assumptions about form of link_defs_info
    #and that self has field local_component_type
    def get_context(link_defs_info)
      ret = LinkDefContext.new()
      #TODO: add back in commented out parts
      # constraints.each{|cnstr|cnstr.get_context_refs!(ret)} 
      attribute_mappings.each{|am|am.get_context_refs!(ret)}
      
      ret.set_values!(self,link_defs_info)
      ret
    end

    class AttributeMapping < HashObject
      def get_context_refs!(ret)
        ret.add_ref!(self[:input])
        ret.add_ref!(self[:output])
      end
      def ret_link(context)
        input_attr,input_path = get_attribute_with_unravel_path(:input,context)
        output_attr,output_path = get_attribute_with_unravel_path(:output,context)
        unless input_attr
          Log.error("cannot find input_id") 
          return nil
        end
        unless output_attr
          Log.error("cannot find output_id")
          return nil
        end
        ret = {:input_id => input_attr[:id],:output_id => output_attr[:id]}
        ret.merge!(:input_path => input_path) if input_path
        ret.merge!(:output_path => output_path) if output_path
        ret
      end
     private
      #returns [attribute,unravel_path]
      def get_attribute_with_unravel_path(dir,context)
        index_map_path = nil
        attr = nil
        ret = [attr,index_map_path]
        attr = context.find_attribute(self[dir][:term_index])
        index_map_path = self[dir][:path]
        #TODO: if treat :create_component_index need to put in here process_unravel_path and process_create_component_index (from link_defs.rb)
        [attr,index_map_path && AttributeLink::IndexMapPath.create_from_array(index_map_path)]
      end
    end

    class Event < HashObject
      def self.create(event,link_def_link)
        case event[:event_type]
          when "extend_component" then EventExtendComponent.new(event,link_def_link)
          else
            raise Error.new("unexpecetd event type")
        end
      end
      def process!(context)
        raise Error.new("Needs to be overwritten")
      end
    end

    class EventExtendComponent < Event
      def initialize(event,link_def_link)
        base_cmp = link_def_link[event[:node] == "remote" ? :remote_component_type : :local_component_type]
        super(event.merge(:base_component =>  base_cmp))
      end

      def process!(context)
        base_component = context.find_component(self[:base_component])
        raise Error.new("cannot find component with ref #{self[:base_component]} in context") unless base_component
        component_extension = base_component.get_extension_in_library(self[:extension_type])
        raise Error.new("cannot find library extension of type #{self[:extension_type]} to #{self[:base_component]} in library") unless component_extension

        #find node to clone it into
        node = (self[:node] == "local") ? context.local_node : context.remote_node
        raise Error.new("cannot find node of type #{self[:node]} in context") unless node

        #clone component into node
        override_attrs = {}
        #TODO: may put in flags to tell clone operation not to do any constraint checking
        clone_opts = {:ret_new_obj_with_cols => [:id,:display_name,:extended_base,:implementation_id]}
        new_cmp = node.clone_into(component_extension,override_attrs,clone_opts)
        
        #if alias is given, update context to reflect this
        if self[:alias]
          context.add_component_ref_and_value!(self[:alias],new_cmp)
        end
      end

      private
      def validate_top_level(hash)
        raise Error.new("node is set incorrectly") if hash[:node] and not [:local,:remote].include?(hash[:node].to_sym)
        raise Error.new("no extension_type is given") unless hash[:extension_type]
      end
    end
  end
end
