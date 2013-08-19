#methods used to maintain the peristence of an assembly instance task template
#TODO: more sophistiacted is using assembly_update to modify the task template if possible
module DTK; class Task; class Template
  class ConfigComponents 
    class Peristence
      def self.remove_outdated_task_templates?(assembly_update)
        task_template_idhs = find_impacted_template_idhs(assembly_update)
        unless task_template_idhs.empty?
          Model.delete_instances(task_template_idhs)
        end
      end

     private
      def self.find_impacted_template_idhs(assembly_update)
        ret = Array.new
        all_templates = assembly_update.assembly_instance().get_task_templates()
        return ret if all.empty?

        all_templates.select{|tt|should_be_removed?(tt,assembly_update)}.map{|tt|tt.id_handle()}
      end

      def self.should_be_removed?(task_template,assembly_update)
        #TODO: stub: conservative clear everything
        true
      end
    end
  end
end; end; end
