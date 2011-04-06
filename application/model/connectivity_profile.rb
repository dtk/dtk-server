module XYZ
  class ConnectivityProfile < ArrayObject
    def initialize(link_def_array,local_type)
      super(link_def_array)
      @local_type = local_type
    end

    def match_component(component,link_type=nil)
      ret = nil
      cmp_type = component[:component_type] && component[:component_type].to_sym
      most_specific_type = component[:most_specific_type] && component[:most_specific_type].to_sym

      #TODO: not looking for multiple matches and just looking for first one (break out of loop when found
      self.each do |one_match|
        next if link_type and not one_match[:type].to_s == link_type.to_s
        (one_match[:possible_links]||[]).each do |link|
          link_cmp_type = link.keys.first
          next unless self.class.component_type_match(cmp_type,most_specific_type,link_cmp_type)

          link_info = link.values.first
          if link_info[:constraints] and not link_info[:constraints].empty?
            Log.error("constraints not implemented yet")
          end
          ret = Aux::hash_subset(one_match,[:required,:type]).merge(:local_type => @local_type, :remote_type => link_cmp_type).merge(link_info)
          if ams = link_info[:attribute_mappings]
            ret.merge!(:attribute_mappings => ams.map{|x|AttributeMapping.parse_and_create(x)})
          end
          if evs = link_info[:events]
            events = evs.map do |trigger,trigger_evs|
              trigger_evs.map{|rhs|LinkDefEvent.parse_and_create(trigger,rhs,link)}
            end.flatten
            ret.merge!(:events => events)
          end
          break
        end
        break if ret
      end
      ret
    end

   private
    def self.component_type_match(cmp_type,most_specific_type,rule_cmp_type)
      return true if (cmp_type == rule_cmp_type or most_specific_type == rule_cmp_type)
      type_class = ComponentType.ret_class(rule_cmp_type)
      type_class and type_class.include?(most_specific_type)
    end
  end

  class LinkDefsExternal < ConnectivityProfile 
    def self.find(component_type)
      ret = nil
      return ret if component_type.nil?
      link_def_array = (get_component_external_link_defs(component_type.to_sym)||{})[:link_defs]
      link_def_array ? self.new(link_def_array,component_type.to_sym) : nil
    end

    def remote_components()
      map{|x|(x[:possible_links]||[]).map{|l|l.keys.first}}.flatten(1)
    end

   private
    def self.get_component_external_link_defs(component_type)
      XYZ::ComponentExternalLinkDefs[component_type]
    end
  end
  
  class LinkDefsInternal < ConnectivityProfile
    #may collapse these with find external functions

    def self.find(component_type)
      ret = nil
      return ret if component_type.nil?
      link_def_array = get_component_internal_link_def_array(component_type.to_sym)
      link_def_array ? self.new(link_def_array,component_type.to_sym) : nil
    end

    def match_other_components(other_components)
      ret = Array.new
      other_components.each do |cmp|
        match = match_component(cmp)
        ret << match.merge(:other_component => cmp) if match
      end
      ret
    end
   private

    def self.get_component_internal_link_def_array(component_type)
      #TODO: stub
      @indexed_intra_conns ||= index_intra_conns(IntraNodeConnections)
      link = @indexed_intra_conns[component_type]
      link ? [{:possible_links => [link]}] : nil
    
    end
    def self.index_intra_conns(x)
      ret = IntraNodeConnections.dup
      x.each do |outside_cmp,v|
        v.each do |inside_cmp,info|
          ret[inside_cmp] ||= Hash.new
          Log.error("unexpected that ret[inside_cmp][outside_cmp] has value") if ret[inside_cmp][outside_cmp]
          ret[inside_cmp][outside_cmp] = info
        end
      end
      ret
    end
  end

  class LinkDefContext < HashObject
    def add_component!(ref,component)
      self[:components] ||= Hash.new
      self[:components][ref] = component
      self
    end
    def find_component(ref)
      (self[:components]||{})[ref]
    end

    def remote_node()
      (self[:nodes]||{})[:remote]
    end
    def local_node()
      (self[:nodes]||{})[:local]
    end
    private
    def create_node_object(component)
      component.id_handle.createIDH(:model_name => :node, :id => component[:node_node_id]).create_object()
    end
  end

  class ExternalLinkDefContext < LinkDefContext
    def initialize(local_cmp,remote_cmp,local_type,remote_type)
      local_node = create_node_object(local_cmp)
      remote_node = create_node_object(remote_cmp)
      hash = {
        :components => {
          local_type =>  local_cmp,
          remote_type =>  remote_cmp
        },
        :nodes => {
          :local => local_node,
          :remote => remote_node
        }
      }
      super(hash)
    end
  end

  class InternalLinkDefContext < LinkDefContext
    def initialize(components)
      hash = {
        :components => components
      }
      super(hash)
    end
  end


  class LinkDefEvent < HashObject
    def self.parse_and_create(trigger,rhs,link)
      if trigger == :on_create_link 
        if rhs.keys.first.to_sym == :extend_component
          LinkDefEventExtendComponent.new(rhs.values.first,link)
        else
          raise Error.new("unexpected link definition right hand side type #{rhs.keys.first}")
        end
      else
        raise Error.new("unexpected link definition event trigger #{hash.keys.first}")
      end
    end
    #processes event and updates context; needs to be overritten
    def process!(context)
      raise Error.new("Needs to be overwritten")
    end
  end

  class LinkDefEventExtendComponent < LinkDefEvent
    def initialize(hash,link)
      validate_top_level(hash)
      new_hash = {
        :node => hash[:node] || :remote,
        :extension_type => hash[:extension_type],
        :base_component => link.keys.first
      }
      new_hash.merge!(:alias => hash[:alias]) if hash.has_key?(:alias)
      super(new_hash)
    end

    def process!(context)
      base_component = context.find_component(self[:base_component])
      raise Error.new("cannot find component with ref #{self[:base_component]} in context") unless base_component
      component_extension = base_component.get_extension_in_library(self[:extension_type])
      raise Error.new("cannot find library extension of type #{self[:extension_type]} to #{self[:base_component]} in library") unless component_extension

      #find node to clone it into
      node = (self[:node] == :local) ? context.local_node : context.remote_node
      raise Error.new("cannot find node of type #{self[:node]} in context") unless node

      #clone component into node
      override_attrs = {:extended_base_id => base_component[:id]}
      #TODO: may put in flags to tell clone operation not to do any constraint checking
      new_cmp_id = node.clone_into(component_extension.id_handle(),override_attrs)

      #if alias is given, update context to reflect this
      if self[:alias]
        new_cmp = base_component.id_handle.createIDH(:model_name => :component, :id => new_cmp_id).create_object()
        context.add_component!(self[:alias],new_cmp)
      end
    end

   private
    def validate_top_level(hash)
     raise Error.new("node is set incorrectly") if hash[:node] and not [:local,:remote].include?(hash[:node])
      raise Error.new("no extension_type is given") unless hash[:extension_type]
    end
  end

  class AttributeMapping < HashObject
    def self.parse_and_create(out_in_hash)
      hash = {
        :input => split_path(out_in_hash.values.first){|x|parse_el(x)},
        :output => split_path(out_in_hash.keys.first){|x|parse_el(x)}
      }
      self.new(hash)
    end
   private
    def self.split_path(path,&block)
      split = path.split(".").map do |el|
        #process special symbols
        Log.error("unexpected token #{el}") unless el =~ AnyTokenRE
        if el =~ IndexedPatRE
          first_part = $1; index = $2
          if index = ":component_index"
            [first_part,"__create_component_index"]
          else
            Log.error("index not treated #{index}")
            el
          end
        else
          el
        end
      end.flatten(1)
      split.map{|el|block.call(el)}
    end
    SimpleTokenPat = 'a-zA-Z0-9_-'
    AnyTokenPat = SimpleTokenPat + '_\[\]:'
    AnyTokenRE = Regexp.new("^[#{AnyTokenPat}]+$") 
    IndexedPatRE = Regexp.new("(^[#{SimpleTokenPat}]+)\\[([:#{SimpleTokenPat}]+)\\]$")

    def self.parse_el(el)
      el =~ /^[0-9]+$/ ? el.to_i : el.to_sym 
    end

   public

    def ret_link(context)
      input_attr,input_path = get_attribute_with_unravel_path(:input,context)
      output_attr,output_path = get_attribute_with_unravel_path(:output,context)
      raise Error.new("cannot find input_id") unless input_attr
      raise Error.new("cannot find output_id") unless output_attr
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
      path = self[dir]
      if is_simple_key?(path[0]) and path.size >= 2 #test that path starts with component
        component = context.find_component(path[0])
        raise Error.new("cannot find component with path ref #{path[0]}") unless component
        attr = component.get_virtual_attribute__include_mixins(path[1].to_s,[:id],:display_name)
        if path.size > 2 
          rest_path = path[2..path.size-1]
          if is_unravel_path?(rest_path)
            index_map_path = process_unravel_path(rest_path,component)
          else
            raise Error.new("Not implemented yet")
          end
        end
      else
        raise Error.new("Not implemented yet")
      end
      [attr,index_map_path && AttributeLink::IndexMapPath.create_from_array(index_map_path)]
    end

    ###parsing functions and related functions
    def is_simple_key?(item)
      item.kind_of?(Fixnum) or ((item.kind_of?(String) or item.kind_of?(Symbol)) and not item.to_s =~ /^__/)
    end

    def is_special_key_type?(type_or_types,item)
      types = Array(type_or_types)
      [String,Symbol].include?(item.class) and types.map{|t|"__#{t}"}.include?(item.to_s)
    end

    def is_unravel_path?(path)
      path.each do |el|
        return false unless is_simple_key?(el) or is_special_key_type?(:create_component_index,el)
      end
      true
    end

    def process_unravel_path(path,component)
      path.map do |el|
        is_special_key_type?(:create_component_index,el) ? process_create_component_index(el,component) : el
      end
    end
    
    def process_create_component_index(item,component)
      {:create_component_index => {:component_idh => component.id_handle()}}
    end
  end
end

