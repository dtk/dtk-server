#methods used to maintain the peristence of an assembly instance task template
#TODO: more sophistiacted is using assembly_update to modify the task template if possible
module DTK; class Task; class Template
  class ConfigComponents 
    class Persistence
      def self.get_content_for(assembly,cmp_actions,task_action=nil)
        if ret = ReifiedObjectCache.get(assembly,task_action)
          return ret
        end
        if serialized_content = get_serialized_content_from_assembly(assembly,task_action)
          Content.parse_and_reify(serialized_content,cmp_actions)
        end
      end

      def self.remove_any_outdated_items(assembly_update)
        ReifiedObjectCache.remove_any_outdated_items(assembly_update)
      end

     private
      def self.get_serialized_content_from_assembly(assembly,task_action=nil)
        ret = assembly.get_task_template(task_action)
        ret && ret.serialized_content_hash_form()
      end

      class ReifiedObjectCache
        #using task_template_id is cache key
        @@cache = Hash.new
        def self.get(assembly,task_action=nil)
          #TODO: stub; nothing in cache
          nil
        end

        def self.remove_any_outdated_items(assembly_update)
          find_impacted_template_idhs(assembly_update).each{|idh|delete_item?(idh)}
        end

       private
        def self.delete_item?(task_template_idh)
          key = key(task_template_idh)
          if @@cache.hash_key?(key)
            @@cache.delete(key)
          end
        end

        def self.add_or_update_item(task_template_idh,content)
          @@cache[key(task_template_idh)] = content
        end
        
        def key(task_template_idh)
          task_template_idh.get_id()
        end
          
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
  end
end; end; end
