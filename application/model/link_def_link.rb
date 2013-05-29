require  File.expand_path('link_def/context', File.dirname(__FILE__))
module DTK
  class LinkDefLink < Model

    def self.common_columns()
      [:id,:group_id,:display_name,:remote_component_type,:position,:content,:type]
    end

    #TODO: when add cardinality info, woudl check it heer
    #assuming that augmented ports have :port_info
    def ret_matches(in_aug_port,out_aug_ports)
      ret = Array.new
      cmp_type = self[:remote_component_type]
      out_aug_ports.each do |out_port|
        if out_port[:port_info][:component_type] == cmp_type
          match =  
            case self[:type]
             when "external"
              in_aug_port[:node_node_id] != out_port[:node_node_id]
             when "internal"
              in_aug_port[:node_node_id] == out_port[:node_node_id]
             else
              raise Error.new("unexpected type for LinkDefLink object")
            end
          if match
            ret << {:input_port => in_aug_port,:output_port => out_port}
          end
        end
      end
      ret
    end

    def self.create_from_serialized_form(link_def_idh,possible_links)
      rows = parse_possible_links(possible_links)
      link_def_id = link_def_idh.get_id()
      rows.each_with_index do |r,i|
        r[:position] = i+1
        r[:link_def_id] = link_def_id
      end
      create_from_rows(model_handle,rows)
    end

    def process(parent_idh,components,opts=Opts.new)
      link_defs_info = components.map{|cmp| {:component => cmp}}
      context = LinkDefContext.create(self,link_defs_info)

      on_create_events.each{|ev|ev.process!(context)} 

      #TODO: not bulking up procssing multiple node group members because dont yet handle case when
      #theer are multiple members taht are output that feed into a node attribute
      links_array = AttributeMapping.ret_links_array(attribute_mappings,context,opts.slice(:raise_error))
      links_array.each do |links|
        #ret_links returns nil only if error such as not being able to find input_id or output_id
        next if links.empty?
        if port_link_idh = opts[:port_link_idh]
          port_link_id = port_link_idh.get_id()
          links.each{|link|link[:port_link_id] = port_link_id}
        end
        AttributeLink.create_attribute_links(parent_idh,links)
      end
    end
    

    def attribute_mappings()
      self[:attribute_mappings] ||= (self[:content][:attribute_mappings]||[]).map{|am|AttributeMapping.new(am)}
    end

    def on_create_events()
      self[:on_create_events]||= ((self[:content][:events]||{})[:on_create]||[]).map{|ev|Event.create(ev,self)}
    end

    class AttributeMapping < HashObject
      def self.ret_links_array(attribute_mappings,context,opts=Opts.new)
        contexts = (context.has_node_group_form?() ? context.node_group_contexts_array() : [context])
        contexts.map{|context|attribute_mappings.map{|am|am.ret_link(context,opts)}.compact}
      end

      def ret_link(context,opts=Opts.new)
        input_attr,input_path = get_attribute_with_unravel_path(:input,context)
        output_attr,output_path = get_attribute_with_unravel_path(:output,context)
        
        err_msgs = Array.new
        unless input_attr
          err_msgs << "attribute (#{pp_form(:input)}) does not exist"
        end
        unless output_attr
          err_msgs << "attribute (#{pp_form(:output)}) does not exist"
        end
        unless err_msgs.empty?
          err_msg = err_msgs.join(" and ").capitalize
          if opts[:raise_error]
            raise ErrorUsage.new(err_msg)
          else
            Log.error(err_msg)
            return nil
          end
        end

        ret = {:input_id => input_attr[:id],:output_id => output_attr[:id]}
        ret.merge!(:input_path => input_path) if input_path
        ret.merge!(:output_path => output_path) if output_path
        ret
      end

      def pp_form(direction)
        ret = 
          if attr = self[direction]
            cmp_type = attr[:component_type]
            attr_name = attr[:attribute_name]
            if cmp_type and attr_name
              "#{Component.pp_component_type(cmp_type)}.#{attr_name}"
            end
          end
        ret||""
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
        override_attrs = {:from_on_create_event => true}
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
