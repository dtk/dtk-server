# methods used to maintain the peristence of an assembly instance task template
# The content can be both node centeric and assembly actions; the class Persistence is responsible for both
# and class AssemblyActions is responsible for just the assembly actions
module DTK; class Task; class Template; class ConfigComponents
  class Persistence
    class AssemblyActions
      def self.get_content_for(assembly, cmp_actions, task_action = nil, opts = {})
        # if task_params given cant use ReifiedObjectCache because params can differ from call to call
        unless opts[:serialized_form] || opts[:task_params]
          if ret = ReifiedObjectCache.get(assembly, task_action)
            return ret
          end
        end

        if serialized_content = get_serialized_content_from_assembly(assembly, task_action, opts)
          if opts[:serialized_form]
            Content.reify(serialized_content)
          else
            Content.parse_and_reify(serialized_content, cmp_actions, opts)
          end
        else
          # raise error if explicit task_action is given and cant be found
          if task_action
            fail TaskActionNotFoundError.new(task_action)
          end
        end
      end

      def self.persist(assembly, template_content, task_action = nil)
        if serialized_content = template_content.serialization_form(allow_empty_task: true, filter: { source: :assembly })
          task_template_idh = Template.create_or_update_from_serialized_content?(assembly.id_handle(), serialized_content, task_action)
          ReifiedObjectCache.add_or_update_item(task_template_idh, template_content)
        else
          if task_template_idh = Template.delete_task_template?(assembly.id_handle(), task_action)
            ReifiedObjectCache.remove_item(task_template_idh)
          end
        end
      end

      def self.remove_any_outdated_items(assembly_update)
        ReifiedObjectCache.remove_any_outdated_items(assembly_update)
      end

      private

      def self.get_serialized_content_from_assembly(assembly, task_action = nil, opts = {})
        ret = assembly.get_task_template(task_action)
        ret && ret.serialized_content_hash_form(opts)
      end

      class ReifiedObjectCache
        # using task_template_id is cache key
        @@cache = {}

        ###TODO: these are in no op mode until implemement
        def self.get(_assembly, _task_action = nil)
          # TODO: stub; nothing in cache
          nil
        end
        def self.add_or_update_item(_task_template_idh, _content)
          #@@cache[key(task_template_idh)] = content
        end

        def self.remove_item(_task_template_idh)
          #@@cache.delete(key(task_template_idh))
        end
        ###TODO: end: these are in no op mode until implememnt

        def self.remove_any_outdated_items(assembly_update)
          find_impacted_template_idhs(assembly_update).each { |idh| delete_item?(idh) }
        end

        private

        def self.delete_item?(task_template_idh)
          key = key(task_template_idh)
          if @@cache.hash_key?(key)
            @@cache.delete(key)
          end
        end

        def self.key(task_template_idh)
          task_template_idh.get_id()
        end

        def self.find_impacted_template_idhs(assembly_update)
          ret = []
          all_templates = assembly_update.assembly_instance().get_task_templates()
          return ret if all.empty?

          all_templates.select { |tt| should_be_removed?(tt, assembly_update) }.map(&:id_handle)
        end

        def self.should_be_removed?(_task_template, _assembly_update)
          # TODO: stub: conservative clear everything
          true
        end
      end
    end
  end
end; end; end; end
