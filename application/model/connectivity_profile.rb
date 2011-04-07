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
          single_link_context = Aux.hash_subset(one_match,[:required,:type]).merge(:local_type => @local_type, :remote_type => link_cmp_type)
          ret = SingleLink.create(single_link_context,link_info)
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

  class SingleLink < HashObject
    def self.create(single_link_context,link_info)
      ret = new(single_link_context)
      if ams = link_info[:attribute_mappings]
        ret.merge!(:attribute_mappings => ams.map{|x|AttributeMapping.parse_and_create(x)})
      end
      if evs = link_info[:events]
        events = evs.map do |trigger,trigger_evs|
          trigger_evs.map{|rhs|LinkDefEvent.parse_and_create(trigger,rhs,single_link_context)}
        end.flatten(1)
        ret.merge!(:events => events)
      end
      if cnstrs = link_info[:constraints]
        ret.merge!(:constraints => LinkDefConstraint.parse_and_create(cnstrs))
      end
      ret
    end

    def get_context(local_cmp,remote_cmp)
      ret = ContextTermValues.new
      constraints = self[:constraints]
      constraints.each{|cnstr|cnstr.get_context_refs!(ret)} if constraints
      ams = self[:attribute_mappings]
      ams.each{|am|am.get_context_refs!(ret)} if ams
      ret.set_values!(self,local_cmp,remote_cmp)
    end
  end

  class ContextTermValues
    def initialize()
      #TODO: if needed put in machanism where terms map to same values so only need to set values once
      @term_mappings = Hash.new
      @node_mappings = Hash.new
      @component_attr_index = Hash.new
    end

    def find_attribute(term_index_x)
      term_index = normalize_term_index(term_index_x)
      match = @term_mappings[term_index]
      match && match.value
    end
    def find_component(term_index_x)
      term_index = normalize_term_index(term_index_x)
      match = @term_mappings[term_index]
      match && match.value
    end
    def remote_node()
      @node_mappings[:remote]
    end
    def local_node()
      @node_mappings[:local]
    end

    def add_ref!(type,term_index_x,*value_ref)
      term_index = normalize_term_index(term_index_x)
      unless @term_mappings.has_key?(term_index)
        @term_mappings[term_index] = 
          case type
           when :component
            ValueComponent.new(*value_ref)
           when :attribute
            cmp_ref = value_ref[0]
            attr_name = value_ref[1].to_s
            v = ValueAttribute.new(*value_ref)
            p = @component_attr_index[cmp_ref] ||= Array.new
            p << {:attribute_name => attr_name,:value_object => v}
            v
           when :link_cardinality
            ValueLinkCardinality.new(*value_ref)
           else
            Log.error("unexpected type #{type}")
            nil
          end
      end
    end

    def add_component_ref_and_value!(cmp_ref,cmp_value)
      term_index = normalize_term_index(cmp_ref)
      add_ref!(:component,term_index,cmp_ref).set_component_value!(cmp_value)

      #update all attributes taht ref this component
      cmp_id = cmp_value[:id]
      attrs_to_get = {cmp_id => @component_attr_index[cmp_ref]}
      component_mh = cmp_value.model_handle()
      get_and_update_component_virtual_attributes!(attrs_to_get,component_mh)
    end

    def set_values!(link_info,local_cmp,remote_cmp)
      [link_info[:local_type],link_info[:remote_type]].each{|t|add_ref!(:component,t,t)}
      @node_mappings = {
        :local => create_node_object(local_cmp),
        :remote => create_node_object(remote_cmp)
      }
      @term_mappings.values.each do |v| 
        v.set_component_remote_and_local_value!(link_info,local_cmp,remote_cmp)
      end
      attrs_to_get = Hash.new
      @term_mappings.each_value do |v|
        if v.kind_of?(ValueAttribute)
          id = v.component_id
          a = attrs_to_get[id] ||= Array.new
          a << {:attribute_name => v.attribute_ref.to_s, :value_object => v}
        end
      end
      component_mh = local_cmp.model_handle()
      get_and_update_component_virtual_attributes!(attrs_to_get,component_mh)
      self
    end
   private

    def get_and_update_component_virtual_attributes!(attrs_to_get,component_mh)
      return if attrs_to_get.empty?
      cols = [:id,:value_derived,:value_asserted]
      from_db = Component.get_virtual_attributes__include_mixins(component_mh,attrs_to_get,cols)
      attrs_to_get.each do |component_id,rest|
        next unless cmp_info = from_db[component_id]
        rest.each do |a|
          attr_name = a[:attribute_name]
          a[:value_object].set_attribute_value!(cmp_info[attr_name]) if cmp_info.has_key?(attr_name)
        end
      end
    end

    def normalize_term_index(t_x)
      t = t_x.to_s
      t =~ /^[^:]/ ? ":#{t}" : t
    end
    
    def create_node_object(component)
      component.id_handle.createIDH(:model_name => :node, :id => component[:node_node_id]).create_object()
    end

    class Value 
      def initialize(component_ref)
        @component_ref = component_ref
        @component = nil
      end

      def set_component_remote_and_local_value!(link_info,local_cmp,remote_cmp)
        if @component_ref == link_info[:local_type]
          @component = local_cmp
        elsif @component_ref == link_info[:remote_type]
          @component = remote_cmp
        else
          Log.error("cannot find ref to component #{@ref}")
        end
      end
      
      def set_component_value!(component)
        @component = component
      end

      def component_id()
        @component && @component[:id]
      end
      #overwrite
      def value()
      end
    end

    class ValueComponent < Value
      def initialize(component_ref)
        super(component_ref)
      end
      def value()
        @component
      end
    end

    class ValueAttribute < Value
      attr_reader :attribute_ref
      def initialize(component_ref,attr_ref)
        super(component_ref)
        @attribute_ref = attr_ref
      end
      def set_attribute_value!(attribute)
        @attribute = attribute
      end
      def value()
        @attribute
      end
    end

    class ValueLinkCardinality < Value
      def initialize(component_ref,attr_ref)
        super(component_ref)
        @attribute_ref = attr_ref
      end
      def set_attribute_value!(attr)
        @attribute =  attr
      end
    end
  end

  #TODO: unify below with above
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

  class InternalLinkDefContext < LinkDefContext
    def initialize(components)
      hash = {
        :components => components
      }
      super(hash)
    end
  end

  module LinkDefParsingMixin
    SimpleTokenPat = 'a-zA-Z0-9_-'
    AnyTokenPat = SimpleTokenPat + '_\[\]:'
    SplitPat = '.'

    def get_context_refs_eq_term!(ret,term_index)
      return unless term_index.kind_of?(String)
      split = term_index.split(SplitPat)
      if split[0] =~ ComponentTermRE
        component = $1.to_sym
      else
        Log.error("unexpected form")
        return
      end
      if split.size == 1
        ret.add_ref!(:component,term_index,component)
      else
        if split[1] =~ AttributeTermRE
          attr = $1.to_sym
        else
          Log.error("unexpected form")
          return
        end
        if split.size == 2
          ret.add_ref!(:attribute,term_index,component,attr)
        elsif split.size == 3 and split[2] == "cardinality"
          ret.add_ref!(:link_cardinality,term_index,component,attr)
        else
          Log.error("unexpected form")
        end
      end
    end
    ComponentTermRE = Regexp.new("^:([#{SimpleTokenPat}]+$)") 
    AttributeTermRE = Regexp.new("^([#{SimpleTokenPat}]+$)") 
  end

  class LinkDefConstraint < HashObject
    include LinkDefParsingMixin
    def self.parse_and_create(constraints)
      #TODO: stub; more efficient would be to group liek constraints under a conjunction
      constraints.map do |cnstr|
        new(:filter => cnstr)
      end
    end

    def get_context_refs!(ret)
      relation = self[:filter]
      if relation.nil?
        Log.error("unexpected form")
      elsif relation[0] == :extension_exists
        get_context_refs_eq_term!(ret,relation[1])
      elsif relation[0] == :eq
        relation[1..2].each{|t|get_context_refs_eq_term!(ret,t)}
      else
        Log.error("unexpected form")
      end
    end
  end

  class LinkDefEvent < HashObject
    def self.parse_and_create(trigger,rhs,single_link_context)
      if trigger == :on_create_link 
        if rhs.keys.first.to_sym == :extend_component
          LinkDefEventExtendComponent.new(rhs.values.first,single_link_context)
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
    def initialize(hash,single_link_context)
      validate_top_level(hash)
      remote_or_local = hash[:node] || :remote
      base_cmp = single_link_context[remote_or_local == :remote ? :remote_type : :local_type]
      new_hash = {
        :node => remote_or_local,
        :extension_type => hash[:extension_type],
        :base_component => base_cmp
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
        context.add_component_ref_and_value!(self[:alias],new_cmp)
      end
    end

   private
    def validate_top_level(hash)
     raise Error.new("node is set incorrectly") if hash[:node] and not [:local,:remote].include?(hash[:node])
      raise Error.new("no extension_type is given") unless hash[:extension_type]
    end
  end

  class AttributeMapping < HashObject
    include LinkDefParsingMixin
    def self.parse_and_create(out_in_hash)
      hash = {
        :input => split_path(out_in_hash.values.first){|x|parse_el(x)},
        :output => split_path(out_in_hash.keys.first){|x|parse_el(x)}
      }
      self.new(hash)
    end
    def get_context_refs!(ret)
      get_context_refs_eq_term!(ret,attr_context_index(self[:input]))
      get_context_refs_eq_term!(ret,attr_context_index(self[:output]))
    end
   private
    def attr_context_index(path)
      #TODO: may parse attribute mapping differently taking first element to be ':component.attr'
      ":#{path[0..1].join(SplitPat)}"
    end
    def self.split_path(path,&block)
      split = path.split(SplitPat).map do |el|
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
    AnyTokenRE = Regexp.new("^[#{AnyTokenPat}]+$") 
    IndexedPatRE = Regexp.new("(^[#{SimpleTokenPat}]+)\\[([:#{SimpleTokenPat}]+)\\]$")

    def self.parse_el(el)
      el =~ /^[0-9]+$/ ? el.to_i : el.gsub(/^:/,"").to_sym 
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
        attr = context.find_attribute(attr_context_index(path))
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

