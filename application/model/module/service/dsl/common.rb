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

    # pattern that appears in dsl that designates a component title
    DSLComponentTitleRegex = /(^.+)\[(.+)\]/

    module InternalForm
      def self.component_ref(cmp_type_ext_form)
        cmp_type_ext_form.gsub(ModCompGsub[:pattern],ModCompGsub[:sub])
      end

      # returns hash with keys
      # component_type,
      # version (optional)
      # component_title (optional)
      def self.component_ref_info(cmp_type_ext_form)
        ref = component_ref(cmp_type_ext_form)
        if ref =~ CmpVersionRegexp
          type = $1; version = $2
        else
          type = ref; version = nil
        end
        if type =~ DSLComponentTitleRegex
          type = $1
          component_title = $2
          ref = ComponentTitle.ref_with_title(type,component_title)
          display_name = ComponentTitle.display_name_with_title(type,component_title)
        end
        ret = {:component_type => type}
        ret.merge!(:version => version) if version
        ret.merge!(:component_title => title) if title
        ret
      end
    end
  end
end
