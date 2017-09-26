#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK
  class ModuleDSL
    class RefIntegrity
      r8_nested_require('ref_integrity', 'snapshot')

      def initialize(component_module)
        @component_module = component_module
        @snapshot = Snapshot.new(component_module)
      end
      private :initialize

      def self.snapshot_associated_assembly_templates(component_module)
        new(component_module)
      end

      def raise_error_if_any_violations(opts = {})
        raise_error_if_dangling_cmp_ref(opts)
        raise_error_if_dangling_port_link()
        # raise_error_if_dangling_cmp_attr_ref()
      end

      def integrity_post_processing
        add_new_ports_on_component_templates()
      end

      def raise_error_if_missing_from_module_refs(include_modules, module_refs_modules = {})
        if inc_modules = include_modules['includes']
          missing = []
          ref_component_modules = module_refs_modules.component_modules.keys
          inc_modules.each do |im|
            missing << im unless ref_component_modules.include?(im.to_sym)
          end

          fail ParsingError::MissingFromModuleRefs.new(modules: missing) unless missing.empty?
        end
      end

      private

      def raise_error_if_dangling_cmp_ref(opts = {})
        # referenced_cmp_template_ids = @snapshot.component_template_ids()
        # DTK-3197: using new snapshot below instead of above because we need to check against updated component_refs when parsing component_defs part, not the initial ones
        new_snapshot = opts[:use_new_snapshot] ? Snapshot.new(@component_module) : @snapshot
        referenced_cmp_template_ids = new_snapshot.component_template_ids()
        return if referenced_cmp_template_ids.empty?
        # this is called within transaction after any deletes are performed (if any)
        # TODO: have ModuleDSL.update_model return if any deletes
        # below is the conservative thing to do if dont know if any deletes
        any_deletes = true
        any_deletes = false if opts[:no_deletes_performed]
        return unless any_deletes

        sp_hash = {
          cols: [:id, :display_name, :group_id],
          filter: [:oneof, :id, referenced_cmp_template_ids]
        }
        cmp_template_ids_still_present = Model.get_objs(model_handle(:component), sp_hash).map { |r| r[:id] }
        referenced_cmp_templates = new_snapshot.referenced_cmp_templates(cmp_template_ids_still_present)
        unless referenced_cmp_templates.empty?
          fail ParsingError::RefComponentTemplates.new(referenced_cmp_templates)
        end
      end

      def raise_error_if_dangling_port_link
        # TODO: stub
      end

      def add_new_ports_on_component_templates
        # find all assembly templates that reference a component template that has a new link def added
        # this is done by taking a new snapshot (one that is post changes) and seeing in any new link defs
        new_snapshot = Snapshot.new(@component_module)
        snapshot_link_def_ids = @snapshot.link_defs.map { |ld| ld[:id] }
        new_links_defs = new_snapshot.link_defs.reject { |ld| snapshot_link_def_ids.include?(ld[:id]) }
        unless new_links_defs.empty?
          link_def_info = new_snapshot.create_link_def_info(new_links_defs)
          ServiceModule::AssemblyImport::PortProcessing.create_assembly_template_ports?(link_def_info)
        end
      end

      def model_handle(model_name)
        @component_module.model_handle(model_name)
      end
    end
  end
end