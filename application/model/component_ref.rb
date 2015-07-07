module DTK
  class ComponentRef < Model
    def self.common_cols
      [:id,:group_id,:display_name,:component_template_id,:has_override_version,:version,:component_type,:template_id_synched]
    end

    def self.ref(component_type,title = nil)
      title ? ComponentTitle.ref_with_title(component_type,title) : component_type
    end
    def self.ref_from_component_hash(cmp_hash)
      title = ComponentTitle.title?(cmp_hash)
      ref(cmp_hash[:component_type],title)
    end

    # TODO: changed this to use '::' form but that broke the port links; determine how display name is used
    # before making any changes; this relates to DTK-1663
    def self.display_name(cmp_type,title = nil)
      title ? ComponentTitle.display_name_with_title(cmp_type,title) : cmp_type
    end

    def display_name_print_form(_opts={})
      cols_to_get = [:component_type,:display_name,:ref_name]
      update_object!(*cols_to_get)
      component_type = self[:component_type] && self[:component_type].gsub(/__/,"::")
      ret = component_type
      # handle component title
      if title = ComponentTitle.title?(self)
        ret = ComponentTitle.print_form_with_title(ret,title)
      end
      ret
    end

    def self.get_referenced_component_modules(project,component_refs)
      ret = []
      return ret if component_refs.empty?
      sp_hash = {
        cols: [:id,:display_name,:group_id,:namespace_info],
        filter: [:oneof, :id, component_refs.map{|r|r[:component_template_id]}.uniq]
      }
      aug_cmp_templates = get_objs(project.model_handle(:component),sp_hash)
      ndx_ret = {}
      aug_cmp_templates.each do |r|
        component_module = r[:component_module]
        ndx = component_module[:id]
        ndx_ret[ndx] ||= component_module.merge(namespace_name: r[:namespace][:display_name])
      end
      ndx_ret.values
    end

    def self.print_form(cmp_ref__obj_or_hash)
      if cmp_ref__obj_or_hash[:component_type]
        Component.component_type_print_form(cmp_ref__obj_or_hash[:component_type])
      elsif cmp_ref__obj_or_hash[:id]
        "id:#{cmp_ref__obj_or_hash[:id]})"
      end
    end
  end
end
