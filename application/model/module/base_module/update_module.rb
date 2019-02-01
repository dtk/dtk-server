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
# TODO: may cleanup: in some methods raise parsing errors and others pass back errors
# if dont want to find multiple errors on single pass we can simplify by having all raise errors and then remove all
# the statements that check whether responds is a parsing error (an usually return imemdiately; so not detecting multiple erros)
module DTK; class BaseModule
  class UpdateModule
    require_relative('update_module/puppet_forge')
    require_relative('update_module/import')
    require_relative('update_module/clone_changes')
    require_relative('update_module/update_module_refs')
    require_relative('update_module/external_refs')
    require_relative('update_module/external_refs')
    require_relative('update_module/create')
    require_relative('update_module/scaffold_implementation')
    include CreateMixin

    def initialize(base_module)
      @base_module  = base_module
      @module_class = base_module.class
    end

    ####### mixin public methods #########
    module ClassMixin
      def import_from_puppet_forge(project, puppet_forge_local_copy, opts = {})
        PuppetForge.new(project, puppet_forge_local_copy, opts).import_module_and_missing_dependencies
      end
    end

    module Mixin
      def import_from_git(commit_sha, repo_idh, version, opts = {})
        Import.new(self, version).import_from_git(commit_sha, repo_idh, opts)
      end

      def import_from_file(commit_sha, repo_idh, version, opts = {})
        Import.new(self, version).import_from_file(commit_sha, repo_idh, opts)
      end

      def update_model_from_clone_changes(commit_sha, diffs_summary, module_branch, version, opts = {})
        CloneChanges.new(self).update_from_clone_changes(commit_sha, diffs_summary, module_branch, version, opts)
      end

      def parse_dsl_and_update_model(impl_obj, module_branch_idh, version, opts = {})
        UpdateModule.new(self).parse_dsl_and_update_model(impl_obj, module_branch_idh, version, opts)
      end

      # called when installing from dtkn catalog
      # returns nil or parsing error
      def process_dsl_and_ret_parsing_errors(repo, module_branch, local, opts = {})
        # Skipping module_ref_update since module being isntalled has this set already so just copy this in
        opts = { update_module_refs_from_file: true }.merge(opts)
        UpdateModule.new(self).process_dsl_and_ret_parsing_errors(repo, module_branch, local, opts)
      end

      # returns the new module branch
      # This is called when creating a service instance specific component module
      def create_new_version__type_specific(repo_for_new_branch, new_version, opts = {})
        local = UpdateModule.ret_local(self, new_version, opts)
        # TODO: this is expensive in that it creates new version by parsing the dsl and reading back in;
        # would be much less expsensive to clone from branch to branch
        opts_update = { update_module_refs_from_file: true }.merge(opts)
        response = UpdateModule.new(self).create_needed_objects_and_dsl?(repo_for_new_branch, local, opts_update)
        response[:module_branch_idh].create_object
      end
    end
    ####### end: mixin public methods #########

    def process_dsl_and_ret_parsing_errors(repo, module_branch, local, opts = {})
      response = create_needed_objects_and_dsl?(repo, local, opts)
      if is_parsing_error?(response)
        response
      else
        module_branch.set_dsl_parsed!(true)
        nil
      end
    end

    # only returns non nil if parsing error; it traps parsing errors
    # opts can contain keys:
    #   :dsl_created_info
    #   :config_agent_type
    #   :ret_parsed_dsl
    #   :update_from_includes
    #   :update_module_refs_from_file
    #   :donot_update_module_refs
    #   :dependent_modules - if not nil then array of strings that are depenedent modules
    def parse_dsl_and_update_model(impl_obj, module_branch_idh, version, opts = {})
      ret                  = nil
      update_node_bindings = nil
      module_branch        = module_branch_idh.create_object

      if version && !version.eql?('') && !version.eql?('master')
        unless version = ModuleVersion.ret(version)
          fail ::DTK::ErrorUsage::BadVersionValue.new(version)
        end
      end

      module_branch.set_dsl_parsed!(false)
      config_agent_type = opts[:config_agent_type] || config_agent_type_default

      dsl_obj = parse_dsl(impl_obj, opts.merge(config_agent_type: config_agent_type))
      return dsl_obj if is_parsing_error?(dsl_obj)

      opts[:ret_parsed_dsl].add(dsl_obj) if opts[:ret_parsed_dsl]

      update_opts = { version: version, use_new_snapshot: opts[:use_new_snapshot], integer_version: opts[:integer_version] }

      # when image_aws component is updated; need to check if new images are added and update node-bindings accordingly
      if self.base_module[:display_name].eql?('image_aws')
        update_node_bindings = check_if_node_bindings_update_needed(self.base_module.get_objs(cols: [:components]), dsl_obj.input_hash)
      end

      dsl_obj.update_model_with_ref_integrity_check(update_opts)

      if update_node_bindings
        images_content = nil

        dsl_obj.input_hash.each_pair do |name, hash_value|
          images_content = hash_value if name.eql?('image_aws')
        end

        update_node_bindings_info(images_content) if images_content
      end

      update_from_includes = {}
      no_errors = true
      if opts[:update_from_includes]
        # Can be both parsing errors, in which case is_parsing_error?(update_from_includes) i strue
        # or can be dependency errors in which case external_deps.any_errors? is true
        # If external_deps.any_errors? error dont yet return so can execute UpdateModuleRefs.save_dsl?
        update_from_includes = UpdateModuleRefs.new(dsl_obj, self.base_module).validate_includes_and_update_module_refs
        return update_from_includes if is_parsing_error?(update_from_includes)

        if external_deps = update_from_includes[:external_dependencies]
          opts[:external_dependencies] = external_deps
          if external_deps.any_errors?
            ret = update_from_includes 
            no_errors = false
          end
        end
      end

      unless opts[:donot_update_module_refs]
        if opts[:update_module_refs_from_file]
          # updating module refs from the component_module_ref file
          # TODO: DTK-3575 don't need this, it was used before module 2.0
          # ModuleRefs::Parse.update_component_module_refs(@module_class, module_branch)
        else
          opts_save_dsl = Opts.create?(message?: update_from_includes[:message], external_dependencies?: external_deps)
          if dsl_updated_info = UpdateModuleRefs.save_dsl?(module_branch, opts_save_dsl)
            if opts[:ret_dsl_updated_info]
              opts[:ret_dsl_updated_info] = dsl_updated_info
            end
          end
        end
      end

      # TODO: double check if opts[:update_from_includes] and opts[:update_module_refs_from_file] mutually exclusive

      unless opts[:update_from_includes]
        module_branch.set_dsl_parsed!(true) unless opts[:dsl_parsed_false]
        return ret
      end

      if no_errors && !opts[:dsl_parsed_false]
        module_branch.set_dsl_parsed!(true)
      end

      ret
    end

    # opts can have keys:
    #   :new_branch_name
    def self.ret_local(base_module, version, opts = {})
      local_params = ModuleBranch::Location::LocalParams::Server.new(
        module_type: base_module.module_type,
        module_name: base_module.module_name,
        namespace: base_module.module_namespace,
        version: version
      )
      local_params.create_local(base_module.get_project, opts)
    end

    def add_dsl_to_impl_and_create_objects(dsl_created_info, project, impl_obj, module_branch_idh, version, opts = {})
      impl_obj.add_file_and_push_to_repo(dsl_created_info[:path], dsl_created_info[:content])
      opts.merge!(project: project, dsl_created_info: dsl_created_info)
      parse_dsl_and_update_model(impl_obj, module_branch_idh, version, opts)
    end

    protected

    attr_reader :base_module, :module_class

    private

    def check_if_node_bindings_update_needed(base_components, new_input_hash)
      update_node_bindings = false
      images_hash          = nil

      new_input_hash.each_pair do |name, ih|
        if name.eql?('image_aws')
          attr_content = ih['attribute']||{}
          images_hash = (attr_content['images']||{})['value_asserted']
          break
        end
      end

      if images_hash
        update_node_bindings = update_node_bindings?(base_components, images_hash)
      end

      update_node_bindings
    end

    def update_node_bindings?(base_components, images_hash)
      if base_image_cmp = (base_components||{}).find{ |bc| bc[:component][:component_type].eql?('image_aws') }
        if images_attribute = base_image_cmp[:component].get_attributes.find{ |attribute| attribute[:display_name].eql?('images') }
          value_asserted = images_attribute[:value_asserted]

          return false if images_hash == value_asserted

          new_images_sorted      = sort_images(images_hash)
          existing_images_sorted = sort_images(value_asserted)

          !(new_images_sorted == existing_images_sorted)
        end
      end
    end

    def sort_images(images)
      sorted = images.inject({}) do |h, (region, value)|
        h.merge(region => value.sort_by{ |key, val| key })
      end
    end

    def update_node_bindings_info(images_content)
      attr_content = images_content['attribute']||{}
      images_hash = (attr_content['images']||{})['value_asserted']
      require File.expand_path('../../../utility/library_nodes', File.dirname(__FILE__))

      nodes_info = prepare_nodes_info(images_hash)

      container_idh = self.base_module.model_handle(:user).create_top
      hash_content = LibraryNodes.get_hash(in_library: 'public', content: nodes_info)
      hash_content['library']['public']['display_name'] ||= 'public'
      Model.import_objects_from_hash(container_idh, hash_content)
    end

    def prepare_nodes_info(images_hash)
      ret = {}

      images_hash.each_pair do |region, i_hash|
        ret.merge!(prepare_type(region, i_hash))
      end

      ret
    end

    def prepare_type(region, i_hash)
      ret = {}

      i_hash.each_pair do |type, t_hash|
        ret[t_hash['ami']] = {
          'region'       => region,
          'type'         => type,
          'os_type'      => t_hash['os_type'],
          'display_name' => type,
          'png'          => "#{type}.png",
          'sizes'        => (t_hash['sizes']||{}).values
        }
      end

      ret
    end

    def ret_local(version)
      self.class.ret_local(self.base_module, version)
    end

    def parse_dsl(impl_obj, opts = {})
      ModuleDSL.parse_dsl(self.base_module, impl_obj, opts)
    end

    def update_component_module_refs(module_branch, matching_module_refs)
      UpdateModuleRefs.update_component_module_refs(module_branch, matching_module_refs, self.base_module)
    end

    def set_dsl_parsed!(boolean)
      self.base_module.set_dsl_parsed!(boolean)
    end

    def module_namespace
      self.base_module.module_namespace
    end

    def module_name
      self.base_module.module_name
    end

    def module_type
      self.base_module.module_type
    end

    def config_agent_type_default
      self.base_module.config_agent_type_default
    end

    def get_project
      self.base_module.get_project
    end

    def is_parsing_error?(response)
      ModuleDSL::ParsingError.is_error?(response)
    end
  end
end; end
