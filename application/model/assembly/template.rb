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
    r8_require('../service_associations')
    r8_nested_require('template', 'factory')
    r8_nested_require('template', 'list')
    r8_nested_require('template', 'pretty_print')
    include PrettyPrint::Mixin
    extend PrettyPrint::ClassMixin

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

    def set_target_key(value)
      tags = get_field?(:tags) || []

      case value
       when true
        tags << 'target' unless tags.include?('target')
       when false
        tags.delete('target') if tags.include?('target')
       else
        fail ErrorUsage.new("Invalid value #{value} for target key. Valid values are: true, false")
       end

      Model.update_from_hash_assignments(id_handle, tags: tags)
    end

    def get_target_key
      if tags = get_field?(:tags)
        tags.include?('target')
      end
    end

    def self.create_from_id_handle(idh)
      idh.create_object(model_name: :assembly_template)
    end

    # opts can have keys:
    #  :service_module - service module object
    #  :service_name - new service name (TODO: code to deprecate can use :assembly_name)
    #  :parent_service_instance
    #  :project
    #  :service_settings - TODO: may be deprecated
    #  :node_size
    #  :os_type
    #  :no_auto_complete - Boolean (default false)
    #  :is_target_service - Boolean (default false)
    #  :service_name_globally_scoped - Boolean (default false); alternative is unique wrt to target
    #  :allow_existing_service - Boolean (default false)
    #  TODO: see if any others used when passing opts to get_augmented_components(opts) and autocomplete_component_links(assembly_instance, aug_cmps, opts)
    def stage(target, opts = Opts.new)
      service_module = opts[:service_module] || get_service_module

      service_module_branch =
        if version = opts[:version]
          service_module.get_module_branch_matching_version(version)
        else
          service_module.get_workspace_module_branch
        end

      # service_module_branch = service_module.get_workspace_module_branch
      unless is_dsl_parsed = service_module_branch.dsl_parsed?
        fail ErrorUsage.new("An assembly template from an unparsed service-module '#{service_module}' cannot be staged")
      end

      # including :description here because it is not a field that gets copied by clone copy processor
      override_attrs = { description: get_field?(:description), service_module_sha: service_module_branch[:current_sha] }
      
      # See if service instance name is passed and if so make sure name not used already
      # TODO: will deprecate opts[:assembly_name] for :service_name
      if service_name = opts[:service_name] || opts[:assembly_name]
        if existing_assembly_instance = Assembly::Instance.exists?(target.model_handle, service_name)
          return existing_assembly_instance if opts[:allow_existing_service]
          fail ErrorUsage.new("Service '#{service_name}' already exists") 
        end
        override_attrs[:display_name] = service_name
      end

      # only if called from stage-target; we set specific_type field to 'target'
      if opts[:is_target_service]
        override_attrs[:specific_type] = 'target'
      else
        # if try to stage target assembly as service instance (non-target service instance)
        fail ErrorUsage.new("Assembly '#{self}' is marked as target assembly and can only be staged as target service instance!") if get_target_key
      end

      clone_opts = { ret_new_obj_with_cols: [:id, :type] }
      if settings = opts[:service_settings]
        clone_opts.merge!(service_settings: settings)
      end

      if version = opts[:version]
        clone_opts.merge!(version: version) unless version.eql?('master')
      end

      new_assembly_obj  = nil
      assembly_instance = nil

      Transaction do
        new_assembly_obj = target.clone_into(self, override_attrs, clone_opts)

        assembly_instance = Assembly::Instance.create_subclass_object(new_assembly_obj)
        assembly_instance_lock = Assembly::Instance::Lock.create_from_element(assembly_instance, service_module, opts)
        assembly_instance_lock.save_to_model

        AssemblyModule::Service.get_or_create_module_for_service_instance(assembly_instance, version: version)

        # user can provide custom node-size and os-type attribute, we proccess them here and assign to nodes
        set_custom_node_attributes(assembly_instance, opts) if opts[:node_size] || opts[:os_type]
      end

      if parent_service_instance = opts[:parent_service_instance]
        ServiceAssociations.create_associations(opts[:project], assembly_instance, parent_service_instance) if assembly_instance
      end

      unless opts[:no_auto_complete]
        aug_cmps = assembly_instance.get_augmented_components(opts)
        LinkDef::AutoComplete.autocomplete_component_links(assembly_instance, aug_cmps, opts)
      end

      assembly_instance
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

    # node_size - master=m3.xlarge,slave=m3.large or m3.xlarge
    # os_type   - precise
    def set_custom_node_attributes(assembly_instance, opts)
      av_pairs = []
      assembly_nodes = assembly_instance.get_nodes.map{ |node| node[:display_name] }
      unless assembly_nodes.empty?
        node_size = opts[:node_size]
        os_type   = opts[:os_type]
        add_node_specific_attributes(assembly_nodes, av_pairs, node_size, os_type) if node_size || os_type
        Attribute::Pattern::Assembly.set_attributes(assembly_instance, av_pairs, opts.merge!(create: true)) unless av_pairs.empty?
      end
    end

    def add_node_specific_attributes(assembly_nodes, av_pairs, node_size_params, os_type_params)
      if n_sizes = node_size_params && node_size_params.split(',')
        added_nodes = []
        n_sizes.each{ |n_size| parse_and_add_attribute(assembly_nodes, av_pairs, n_size, added_nodes, "instance_size") }
      end
      if os_types = os_type_params && os_type_params.split(',')
        added_nodes = []
        os_types.each{ |os_type| parse_and_add_attribute(assembly_nodes, av_pairs, os_type, added_nodes, "os_identifier") }
      end
    end

    def parse_and_add_attribute(assembly_nodes, av_pairs, param, added_nodes, attribute)
      if param.include?('=')
        n_name, n_size = param.split('=')
        added_nodes << n_name

        fail ErrorUsage.new("Node '#{n_name}' specified in params does not exist in assembly template!") unless assembly_nodes.include?(n_name)
        av_pairs << {pattern: "#{n_name}/#{attribute}", value: "#{n_size}"}
      else
        assembly_nodes.each do |assembly_node|
          av_pairs << {pattern: "#{assembly_node}/#{attribute}", value: "#{param}"} unless added_nodes.include?(assembly_node)
        end
      end
    end

  end
end
# TODO: hack to get around error in /home/dtk/server/system/model.rb:31:in `const_get
AssemblyTemplate = Assembly::Template
end
