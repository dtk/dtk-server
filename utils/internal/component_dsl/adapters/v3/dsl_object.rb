module DTK; class ComponentDSL; class V3
  DSLObjectBase = ComponentDSL::V2::DSLObject
  class DSLObject < DSLObjectBase
    class Attribute < DSLObjectBase::Attribute
      def render_hash_form(opts={})
        ret = RenderHash.new
        ret.set_unless_nil("description",value(:description))
        ret["type"] = required_value(:type)
        ret["required"] = true if value(:required)
        ret.set_unless_nil("dynamic",converted_dynamic())
        ret.set_unless_nil("default",converted_default())
        ret.set_unless_nil("external_ref",converted_external_ref())
        ret
      end

     private
      def converted_dynamic()
        ret = value(:dynamic)
        if ret.nil? then (has_default_variable?() ? true : nil)
        else ret
        end
      end

      def converted_default()
        if has_default_variable?() 
          ExtRefPuppetHeader
        end
      end
      ExtRefPuppetHeader = 'external_ref(puppet_header)'

      def has_default_variable?()
        !(value(:external_ref) ||{})["default_variable"].nil?
      end

      def converted_external_ref()
        ret = RenderHash.new
        ext_ref = required_value(:external_ref)
        attr_name = ext_ref["name"]
        unless attr_name == value(:id)
          ret[ext_ref["type"]] = attr_name
        end
        #catchall: ignore proceesed keys and default_variable 
        (ext_ref.keys - ["name","type","default_variable"]).each{|k|ret[k] = ext_ref[k]}
        ret.empty? ? nil : ret
      end
    end
  end
end; end; end
