module DTK
  module ServiceDSLCommonMixin
    Seperators = {
      :module_component => "::", #TODO: if this changes need to change ModCompGsub
      :component_version => ":",
      :component_port => "/",
      :assembly_node => "/",
      :node_component => "/",
      :component_link_def_ref => "/"
    }
    ModCompInternalSep = "__" #TODO: if this changes need to chage ModCompGsub[:sub]
    ModCompGsub = {
      :pattern => /(^[^:]+)::/, 
      :sub => '\1__'
    }
    CmpVersionRegexp = Regexp.new("(^.+)#{Seperators[:component_version]}([0-9]+.+$)")

    module InternalForm
      def self.component_ref(cmp_type_ext_form)
        cmp_type_ext_form.gsub(ModCompGsub[:pattern],ModCompGsub[:sub])
      end

      # returns [ref,component_type,version] where version can be nil
      def self.component_ref_type_and_version(cmp_type_ext_form)
        ref = component_ref(cmp_type_ext_form)
        if ref =~ CmpVersionRegexp
          type = $1; version = $2
        else
          type = ref; version = nil
        end
        [ref,type,version]
      end
    end
  end
end
