module DTK 
  class ComponentRef < Model
    def self.get_referenced_component_modules(project,component_refs)
      template_ids_to_get = Array.new
      component_types = Array.new
      component_refs.each do |r|
        unless r[:component_type] or r[:component_template_id]
          update_object(:component_type,:component_template_id)
        end
        if r[:component_type]
          component_types << r[:component_type]
        else
          template_ids_to_get << r[:component_template_id]
        end
      end
      
      unless template_ids_to_get.empty?
        sp_hash = {
          :cols => [:component_type],
          :filter => [:oneof, :id, template_ids_to_get]
        }
        get_objs(project.model_handle(:component),sp_hash).each do |r|
          component_types << r[:component_type]
        end
      end

      return ret if component_types.empty?
      module_names = component_types.uniq.map{|r|Component.module_name(r)}
      sp_hash = {
        :cols => [:id,:group_id,:display_name],
        :filter => [:and,[:eq,:project_project_id,project[:id]],[:oneof,:display_name,module_names]]
      }
      
      get_objs(project.model_handle(:component_module),sp_hash)
    end

  end
end
