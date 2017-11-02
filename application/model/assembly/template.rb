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
module DTK; class Assembly
  class Template < self
    require_relative('template/factory')
    require_relative('template/list')
    require_relative('template/pretty_print')
    require_relative('template/stage')
    include PrettyPrint::Mixin
    extend PrettyPrint::ClassMixin
    include Stage::Mixin


    def get_objs(sp_hash, opts = {})
      super(sp_hash, opts.merge(model_handle: model_handle().createMH(:assembly_template)))
    end
    def self.get_objs(mh, sp_hash, opts = {})
      if mh[:model_name] == :assembly_template
        get_these_objs(mh, sp_hash, opts)
      else
        super
      end
    end

    def self.create_from_id_handle(idh)
      idh.create_object(model_name: :assembly_template)
    end

    def self.create_or_update_from_instance(project, assembly_instance, service_module_name, assembly_template_name, opts = {})
      service_module = Factory.get_or_create_service_module(project, service_module_name, opts)
      merge_message = Factory.create_or_update_from_instance(assembly_instance, service_module, assembly_template_name, opts)
      service_module.merge!(merge_warning_message: merge_message) if merge_message

      service_module_branch = service_module.get_workspace_module_branch()
      service_module_branch.set_dsl_parsed!(true)

      service_module
    end

    ### standard get methods
    def get_nodes(opts = {})
      self.class.get_nodes([id_handle()], opts)
    end
    def self.get_nodes(assembly_idhs, opts = {})
      ret = []
      return ret if assembly_idhs.empty?()
      sp_hash = {
        cols: opts[:cols] || [:id, :group_id, :display_name, :assembly_id],
        filter: [:oneof, :assembly_id, assembly_idhs.map(&:get_id)]
      }
      node_mh = assembly_idhs.first.createMH(:node)
      get_objs(node_mh, sp_hash)
    end

    def self.get_ndx_assembly_names_to_ids(project_idh, service_module, assembly_names)
      ndx_assembly_refs = assembly_names.inject({}) { |h, n| h.merge(n => service_module.assembly_ref(n)) }
      sp_hash = {
        cols: [:id, :group_id, :display_name, :ref],
        filter: [:and, [:eq, :project_project_id, project_idh.get_id], [:oneof, :ref, ndx_assembly_refs.values]]
      }
      assembly_templates = get_objs(project_idh.createMH(:component), sp_hash, keep_ref_cols: true)
      ndx_ref_ids = assembly_templates.inject({}) { |h, r| h.merge(r[:ref] => r[:id]) }
      ndx_assembly_refs.inject({}) do |h, (name, ref)|
        id = ndx_ref_ids[ref]
        id ? h.merge(name => id) : h
      end
    end

    def self.augment_with_namespaces!(assembly_templates)
      ndx_namespaces = get_ndx_namespaces(assembly_templates)
      assembly_templates.each do |a|
        if namespace = ndx_namespaces[a[:id]]
          a[:namespace] ||= namespace
        end
      end
      assembly_templates
    end

    # indexed by assembly_template id
    def self.get_ndx_namespaces(assembly_templates)
      ret = {}
      return ret if assembly_templates.empty?
      sp_hash = {
        cols: [:id, :group_id, :display_name, :module_branch_id, :assembly_template_namespace_info],
        filter: [:oneof, :id, assembly_templates.map(&:id)]
      }
      mh = assembly_templates.first.model_handle()
      get_objs(mh, sp_hash).inject({}) do |h, r|
        h.merge(r[:id] => r[:namespace])
      end
    end
    private_class_method :get_ndx_namespaces

    def get_settings(opts = {})
      sp_hash = {
        cols: opts[:cols] || ServiceSetting.common_columns(),
        filter: [:eq, :component_component_id, id()]
      }
      service_setting_mh = model_handle(:service_setting)
      Model.get_objs(service_setting_mh, sp_hash)
    end

    def self.get_augmented_component_refs(mh, opts = {})
      sp_hash = {
        cols: [:id, :display_name, :component_type, :module_branch_id, :augmented_component_refs],
        filter: [:and, [:eq, :type, 'composite'], [:neq, :project_project_id, nil], opts[:filter]].compact
      }
      assembly_rows = get_objs(mh.createMH(:component), sp_hash)

      # look for version contraints which are on a per component module basis
      aug_cmp_refs_ndx_by_vc = {}
      assembly_rows.each do |r|
        component_ref = r[:component_ref]
        unless component_type = component_ref[:component_type] || (r[:component_template] || {})[:component_type]
          Log.error("Component ref with id #{r[:id]}) does not have a component type associated with it")
        else
          service_module_name = service_module_name(r[:component_type])
          pntr = aug_cmp_refs_ndx_by_vc[service_module_name]
          unless pntr
            component_module_refs = opts[:component_module_refs] || ModuleRefs.get_component_module_refs(mh.createIDH(model_name: :module_branch, id: r[:module_branch_id]).create_object())

            pntr = aug_cmp_refs_ndx_by_vc[service_module_name] = {
              component_module_refs: component_module_refs
            }
          end
          aug_cmp_ref = r[:component_ref].merge(r.hash_subset(:component_template, :node))
          (pntr[:aug_cmp_refs] ||= []) << aug_cmp_ref
        end
      end
      set_matching_opts = Aux.hash_subset(opts, [:force_compute_template_id])
      aug_cmp_refs_ndx_by_vc.each_value do |r|
        r[:component_module_refs].set_matching_component_template_info?(r[:aug_cmp_refs], set_matching_opts)
      end
      aug_cmp_refs_ndx_by_vc.values.map { |r| r[:aug_cmp_refs] }.flatten
    end
    ### end: standard get methods

    def self.service_module_name(component_type_field)
      component_type_field.gsub(/__.+$/, '')
    end
    private_class_method :service_module_name

    def self.list(assembly_mh, opts = {})
      List.list(assembly_mh, opts)
    end

    def info_about(about, _opts = Opts.new)
      case about
       when :components
        List.list_components(self, name_with_version: true)
       when :nodes
        List.list_nodes(self)
       else
        fail Error.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
    end

    def self.list_modules(assembly_templates)
      List.list_modules(assembly_templates)
    end

    def self.get(mh, opts = {})
      sp_hash = {
        cols: opts[:cols] || [:id, :group_id, :display_name, :component_type, :module_branch_id, :description, :service_module, :version],
        filter: [:and, [:eq, :type, 'composite'],
                 opts[:project_idh] ? [:eq, :project_project_id, opts[:project_idh].get_id()] : [:neq, :project_project_id, nil],
                 opts[:filter],
                 opts[:version_filter]
                   ].compact
      }
      ret = get_these_objs(mh, sp_hash, keep_ref_cols: true)
      ret.each { |r| r[:version] ||= (r[:module_branch] || {})[:version] }
      ret
    end

    def self.list_virtual_column?(detail_level = nil)
      if detail_level.nil?
        nil
      elsif detail_level == 'nodes'
        :template_stub_nodes
      else
        fail Error.new("not implemented list_virtual_column at detail level (#{detail_level})")
      end
    end

    def self.delete_and_ret_module_repo_info(assembly_idh)
      ServiceModule.check_service_instance_references(assembly_idh)

      # first delete the dsl files
      module_repo_info = ServiceModule.delete_assembly_dsl?(assembly_idh)
      # need to explicitly delete nodes, but not components since node's parents are not the assembly, while component's parents are the nodes
      # do not need to delete port links which use a cascade foreign key
      delete_model_objects(assembly_idh)
      module_repo_info
    end

    def self.delete_model_objects(assembly_idh)
      delete_assemblies_nodes([assembly_idh])
      delete_instance(assembly_idh)
    end

    def self.delete_assemblies_nodes(assembly_idhs)
      ret = []
      return ret if assembly_idhs.empty?
      node_idhs = get_nodes(assembly_idhs).map(&:id_handle)
      Model.delete_instances(node_idhs)
    end

    def self.check_valid_id(model_handle, id)
      filter =
        [:and,
         [:eq, :id, id],
         [:eq, :type, 'composite'],
         [:neq, :project_project_id, nil]]
      check_valid_id_helper(model_handle, id, filter)
    end
    def self.name_to_id(model_handle, name)
      parts = name.split('/')
      augmented_sp_hash =
        if parts.size == 1
          { cols: [:id, :component_type],
            filter: [:and,
                     [:eq, :component_type, pp_name_to_component_type(parts[0])],
                     [:eq, :type, 'composite'],
                     [:neq, :project_project_id, nil]]
          }
        else
        fail ErrorNameInvalid.new(name, pp_object_type())
      end
      name_to_id_helper(model_handle, name, augmented_sp_hash)
    end

    def self.get_service_module?(project, service_module_name, namespace)
      ret = nil
      sp_hash = {
        cols: [:id, :group_id, :display_name, :namespace],
        filter: [:eq, :display_name, service_module_name]
      }
      get_objs(project.model_handle(:service_module), sp_hash).find { |r| r[:namespace][:display_name] == namespace }
    end

    # TODO: probably move to Assembly
    def model_handle(mn = nil)
      super(mn || :component)
    end

    private

    ModuleTemplateSep = '__'

    # returns [service_module_name,assembly_name]
    def self.parse_component_type(component_type)
      component_type.split(ModuleTemplateSep)
    end

    def self.component_type(service_module_name, template_name)
      "#{service_module_name}#{ModuleTemplateSep}#{template_name}"
    end

  end
end
# TODO: hack to get around error in /home/dtk/server/system/model.rb:31:in `const_get
AssemblyTemplate = Assembly::Template
end
