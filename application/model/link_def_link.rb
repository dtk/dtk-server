require  File.expand_path('link_def/context', File.dirname(__FILE__))
module DTK
  class LinkDefLink < Model
    r8_nested_require('link_def_link','attribute_mapping')

    def self.common_columns()
      [:id,:group_id,:display_name,:remote_component_type,:position,:content,:type,:temporal_order]
    end

    def matching_attribute_mapping?(dep_attr_pattern,antec_attr_pattern)
      attribute_mappings().each do |am|
        if ret = am.match_attribute_patterns?(dep_attr_pattern,antec_attr_pattern)
          return ret
        end
      end
      nil
    end

    def add_attribute_mapping(dep_attr_pattern,antec_attr_pattern)
      updated_attr_mappings = attribute_mappings() + [AttributeMapping.create_from_attribute_patterns(dep_attr_pattern,antec_attr_pattern)]
      update_attribute_mappings(updated_attr_mappings)
    end

    #TODO: when add cardinality contrsaints on links, would check it here
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

    def process(parent_idh,components,opts={})
      link_defs_info = components.map{|cmp| {:component => cmp}}
      context = LinkDefContext.create(self,link_defs_info)

      on_create_events.each{|ev|ev.process!(context)} 

      #TODO: not bulking up procssing multiple node group members because dont yet handle case when
      #theer are multiple members taht are output that feed into a node attribute
      links_array = AttributeMapping.ret_links_array(attribute_mappings,context,:raise_error => opts[:raise_error])
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

    def update_attribute_mappings(new_attribute_mappings)
pp [:new_attribute_mappings,new_attribute_mappings]
      ret = self[:attribute_mappings] = new_attribute_mappings
      self[:content] ||= Hash.new
      self[:content][:attribute_mappings] = ret
      update({:content => self[:content]},:convert => true)
      ret
    end

    def attribute_mappings()
      self[:attribute_mappings] ||= (self[:content][:attribute_mappings]||[]).map{|am|AttributeMapping.reify(am)}
    end

    def on_create_events()
      self[:on_create_events]||= ((self[:content][:events]||{})[:on_create]||[]).map{|ev|Event.create(ev,self)}
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
