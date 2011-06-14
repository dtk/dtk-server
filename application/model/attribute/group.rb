module XYZ
  class AttrValType
    def self.create(type,attr)
      klass = AttrValTypeMap[type.to_sym]
      if klass then klass.new(type,attr)
      else raise Error.new("attribute value type (#{type}) not treated")
      end
    end
    def type_of?(*types)
      types.find do |type|
        #procssing of types ortogonal to type hierarchy
        if type == :required_not_dynamic
          @required and not @dynamic
        else
          unless type_klass = AttrValTypeMap[type]
            Log.error("illegal type given #{type}")
            next
          end
          self.kind_of?(type_klass)
        end
      end ? true : nil
    end
   private
    def initialize(type,attr)
      @type=type.to_sym
      @required = attr[:required]
      @dynamic = attr[:dynamic]
    end
  end
  #TODO: may add distinction between set through default value versus set directly
  class AttrValTypeUnset < AttrValType
  end
  class AttrValTypeUnsetRequired < AttrValTypeUnset
  end
  class AttrValTypeUnsetNotRequired < AttrValTypeUnset
  end
  class AttrValTypeSet < AttrValType
  end
  class AttrValTypeSetAsserted < AttrValTypeSet
  end
  class AttrValTypeSetDerived < AttrValTypeSet
  end
  class AttrValTypeSetDynamic < AttrValTypeSet
  end
  AttrValTypeMap = {
    :unset_required => AttrValTypeUnsetRequired,
    :unset_not_required => AttrValTypeUnsetNotRequired,
    :set => AttrValTypeSet,
    :set_asserted => AttrValTypeSetAsserted,
    :set_derived => AttrValTypeSetDerived,
    :set_dynamic => AttrValTypeSetDynamic,
  }

  module AttributeGroupInstanceMixin
    def attribute_value_type()
      #TODO: detecting legititamate null value
      type = 
        if self[:value_asserted] then :set_asserted
        elsif self[:value_derived] then :set_derived
        elsif self[:dynamic] and self[:port_type] == "input" then :set_dynamic
        elsif self[:required] then :unset_required
        else :unset_not_required
       end
      raise Error.new("Cannot detect type of attribute") unless type
      AttrValType.create(type,self)
    end
  end
  module AttributeGroupClassMixin
    def ret_grouped_attributes(augmented_attr_list,opts={})
      prune_set = opts[:types_to_keep]
      ret = Array.new
      augmented_attr_list.each do |attr|
        type = attr.attribute_value_type()
        ret << attr.merge(:attr_val_type => type) if prune_set.nil? or type.type_of?(*prune_set)
      end
      ret
    end
    def augmented_attribute_list_from_task(task)
      component_actions = task.component_actions
      ret = Array.new 
      component_actions.each do |action|
        AttributeComplexType.flatten_attribute_list(action[:attributes],:flatten_nil_value=>true).each do |attr|
          ret << attr.merge(:component => action[:component], :node => action[:node])
        end
      end
      ret
    end
  end
end
