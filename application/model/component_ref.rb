module DTK
  class ComponentRef < Model
    def self.common_cols()
      [:id,:group_id,:display_name,:component_template_id,:has_override_version,:version,:component_type,:template_id_synched]
    end

    def display_name_print_form(opts={})
      cols_to_get = [:component_type,:display_name,:ref_name]
      update_object!(*cols_to_get)
      component_type = self[:component_type] && self[:component_type].gsub(/__/,"::")
      ret = component_type
      # handle component title
      # NOTE: ref_num is for dsl versions before v2
      if title = ComponentTitle.title?(self)||self[:ref_num]
        ret = ComponentTitle.print_form_with_title(ret,title)
      end
      ret
    end


    def self.get_referenced_component_modules(project,component_refs)
      ret = Array.new
      return ret if component_refs.empty?
      sp_hash = {
        :cols => [:id,:display_name,:group_id,:namespace_info],
        :filter => [:oneof, :id, component_refs.map{|r|r[:component_template_id]}.uniq]
      }
      aug_cmp_templates = get_objs(project.model_handle(:component),sp_hash)
      aug_cmp_templates.map do |r|
        r[:component_module].merge(:namespace_name => r[:namespace][:display_name])
      end
    end

    def self.print_form(cmp_ref__obj_or_hash)
      if cmp_ref__obj_or_hash[:component_type]
        Component.component_type_print_form(cmp_ref__obj_or_hash[:component_type])
      elsif cmp_ref__obj_or_hash[:id]
        "id:#{cmp_ref__obj_or_hash[:id].to_s})"
      end
    end

  end
end
