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
module DTK; class LinkDef
  class AutoComplete
    def self.autocomplete_component_links(assembly, link_def_components, opts = Opts.new)
      opts = add_detail_to_include_component_dependencies?(opts)
      aug_cmps = assembly.get_augmented_components(opts)

      # if service instance is staged into service instance target,
      # find matching components from parent target as well
      if parent_service_instance = opts[:parent_service_instance]
        parent_cmps = parent_service_instance.get_augmented_components(opts)
        aug_cmps.concat(parent_cmps)
      end

      link_def_components.each do |link_def_cmp|
        input_cmp_idh = link_def_cmp.id_handle()
        link_matching_components(assembly, input_cmp_idh, aug_cmps)
      end
    end

    # TODO: AUTO-COMPLETE-LINKS: this needs to be enhanced to be a general mechanism to auto complete links
    def self.create_internal_links(_node, component, node_link_defs_info)
      # get link_defs in node_link_defs_info that relate to internal links not linked already that connect to component
      # on either end. what is returned are link defs annotated with their possible links
      relevant_link_defs = get_annotated_internal_link_defs(component, node_link_defs_info)
      return if relevant_link_defs.empty?
      # for each link def with multiple possibel link defs find the match;
      # TODO: find good mechanism to get user input if there is a choice such as whether it is internal or external
      # below is exeperimenting with passing in "stratagy" object, which for example can indicate to make all "internal_external internal"
      strategy = { internal_external_becomes_internal: true, select_first: true }
      parent_idh = component.id_handle.get_parent_id_handle_with_auth_info()
      attr_links = []
      relevant_link_defs.each do |link_def|
        if link_def_link = choose_internal_link(link_def, link_def[:possible_links], link_def[:component], strategy)
          link_def_context = LinkDef::Context.create(link_def_link, node_link_defs_info)
          link_def_link.attribute_mappings.each do |attr_mapping|
            attr_links << attr_mapping.ret_links__clone_if_needed(link_def_context).merge(type: 'internal')
          end
        end
      end
      AttributeLink.create_attribute_links(parent_idh, attr_links)
    end

    private

    def self.add_detail_to_include_component_dependencies?(opts)
      detail_to_include = opts[:detail_to_include] || []
      if detail_to_include.include?(:component_dependencies)
        opts
      else
        detail_to_include = detail_to_include + [:component_dependencies] 
        opts.merge(detail_to_include: detail_to_include)
      end
    end

    def self.link_matching_components(assembly, input_cmp_idh, aug_cmps)
      components = aug_cmps.select{ |cmp| cmp[:id] == input_cmp_idh[:guid] }

      return if components.empty?

      if components.size > 1
        Log.info('WARNING: Unexpected that components size is more than one')
        return
      end

      component = components.first
      if dependencies = component[:dependencies]
        unlinked_link_defs = get_unlinked_link_defs(dependencies)
        Log.info("Auto-linking components output:")
        Log.info("#{component[:id]} => nil") if unlinked_link_defs.empty?

        unlinked_link_defs.each do |link_def|
          matching_cmps = check_if_matching_cmps(link_def, aug_cmps, component)
          if matching_cmps.empty?
            Log.info("#{component[:id]} => { #{link_def} => [] }")
          elsif matching_cmps.size > 1
            Log.info("#{component[:id]} => { #{link_def} => #{matching_cmps} }")
          else
            Log.info("#{component[:id]} => { #{link_def} => #{matching_cmps} }")
            matching_cmp = matching_cmps.first
            output_cmp_idh = matching_cmp.id_handle()
            assembly.add_service_link?(input_cmp_idh, output_cmp_idh)
          end
        end
      end
    end

    def self.get_unlinked_link_defs(dependencies)
      ret_link_defs = []

      dependencies.each do |dep|
        if link_def = dep.respond_to?(:link_def) && dep.link_def
          ret_link_defs << link_def if dep.satisfied_by_component_ids.empty?
        end
      end

      ret_link_defs
    end

    def self.check_if_matching_cmps(link_def, aug_cmps, this_cmp)
      matching_cmps  = []
      constraints    = nil
      preferences    = nil
      link_def_links = LinkDef.get_link_def_links([link_def.id_handle()], cols: [:id, :display_name, :content, :link_def_id])

      # get constraints from link_def dsl content and use them later to match link_defs on auto-complete
      if link_def_content = !link_def_links.empty? && link_def_links.first[:content]
        unless link_def_content.empty?
          constraints = link_def_content[:constraints]
          preferences = link_def_content[:preferences]
        end
      end

      preferences_matching_cmps = []
      if link_type = link_def[:link_type]
        aug_cmps.each do |cmp|
          cmp_name = cmp[:component_type].gsub('__','::')

          if node = link_type.include?('/') && cmp[:node]
            cmp_name = "#{node[:display_name]}/#{cmp_name}"
          end

          if link_type.eql?(cmp_name)
            matching_cmps << cmp if constraints.nil? && preferences.nil?

            if constraints && matching_constraints?(constraints, cmp, this_cmp)
              matching_cmps << cmp
            end

            if index = preferences && matching_constraints?(preferences, cmp, this_cmp, { preferences: true })
              preferences_matching_cmps[index] = cmp
            end
          end
        end
      end

      return matching_cmps if matching_cmps.size == 1

      unless preferences_matching_cmps.empty?
        return get_matching_by_preferences(preferences_matching_cmps, matching_cmps)
      end

      matching_cmps
    end

    def self.choose_internal_link(_link_def, possible_links, link_base_cmp, strategy)
      # TODO: mostly stubbed fn
      # TODO: need to check if has contraint
      ret = nil
      return ret if possible_links.empty?
      fail Error.new('only select_first stratagy currently implemented') unless strategy[:select_first]
      ret = possible_links.first
      if ret[:type] == 'internal_external'
        fail Error.new('only strategy internal_external_becomes_internal implemented') unless stratagy[:internal_external_becomes_internal]
      end
      link_base_cmp.update_object!(:component_type)
      ret.merge(local_component_type: link_base_cmp[:component_type])
    end

    def self.get_annotated_internal_link_defs(component, node_link_defs_info)
      ret = []
      # shortcut; no links to create if less than two internal ports
      return ret if node_link_defs_info.size < 2

      #### get relevant link def possible links
      # find all link def ids that can be internal, local, and not connected already
      component_id = component.id
      component_type = (component.update_object!(:component_type))[:component_type]
      relevant_link_def_ids = []
      cmp_link_def_ids = [] # subset of above on this component
      ndx_relevant_link_defs = {} #for splicing in possible_links TODO: see if more efficient to get possible_links
      # in intial call to get node_link_defs_info
      # these are the ones for which the possible links shoudl be found
      node_link_defs_info.each do |r|
        port = r[:port]
        if port.nil?
          Log.info('TODO: Check if port.nil? is an error in .get_annotated_internal_link_defs')
          next
        end
        link_def = r[:link_def]
        component = r[:component]
        if %w(component_internal component_internal_external).include?(port[:type]) &&
            link_def[:local_or_remote] == 'local' and
            not port[:connected]
          link_def_id = link_def[:id]
          relevant_link_def_ids << link_def_id
          ndx_relevant_link_defs[link_def_id] = link_def.merge(component: component)
          cmp_link_def_ids << link_def_id if link_def[:component_component_id] == component_id
        end
      end
      return ret if relevant_link_def_ids.empty?

      # get relevant possible_link link defs; these are ones that
      # are children of relevant_link_def_ids and
      # internal_external have link_def_id in cmp_link_def_ids or remote_component_type == component_type
      sp_hash = {
        cols: [:link_def_id, :remote_component_type, :position, :content, :type],
        filter: [:and, [:oneof, :type, %w(internal internal_external)],
                 [:oneof, :link_def_id, relevant_link_def_ids],
                 [:or, [:eq, :remote_component_type, component_type],
                  [:oneof, :link_def_id, cmp_link_def_ids]]],
        order_by: [{ field: :position, order: 'ASC' }]
      }
      poss_links = Model.get_objs(component.model_handle(:link_def_link), sp_hash)
      return ret if poss_links.empty?
      # splice in possible links
      poss_links.each do |poss_link|
        (ndx_relevant_link_defs[poss_link[:link_def_id]][:possible_links] ||= []) << poss_link
      end

      # relevant link defs are ones that are in ndx_relevant_link_defs_info and have a possible link
      ret = ndx_relevant_link_defs.reject { |_k, v| not v.key?(:possible_links) }.values
      ret
    end

    private

    def self.matching_constraints?(constraints_or_preferences, dep_cmp, this_cmp, opts = {})
      constraints_matched = true

      constraints_or_preferences.each_with_index do |constraint, index|
        begin
          # using $SAFE = 4 to stop users from executing malicious code in lambda scripts
          evaluated_fn = proc do
            $SAFE = 4
            eval(constraint)
          end.call

          raise Error.new('Currently only lambda functions are supported!') unless evaluated_fn.is_a?(Proc) && evaluated_fn.lambda?

          attributes          = parse_constraint_attributes(evaluated_fn, dep_cmp, this_cmp)
          constraints_matched = evaluated_fn.call(*attributes)

          # if checking preferences, validate each of them
          if opts[:preferences]
            if constraints_matched
              return index
            else
              next
            end
          end

          # if checking constraints (not preferences) one of constrains not met, we exit the loop and return false
          break unless constraints_matched
        rescue SecurityError => e
          pp [e, e.backtrace[0..5]]
          raise e
        end
      end

      return opts[:preferences] ? false : constraints_matched
    end

    def self.get_matching_by_preferences(preferences_matching_cmps, matching_cmps)
      preferences_matching_cmps.delete_if{ |pref| pref.nil? }
      if matching_cmps.size > 1
        preferences_matching_cmps.each do |pref|
          return [pref] if matching_cmps.include?(pref)
        end
      else
        return [preferences_matching_cmps.first]
      end
    end

    def self.parse_constraint_attributes(evaluated_fn, dep_cmp, this_cmp)
      attributes = []
      lambda_params = evaluated_fn.parameters

      dep_cmp_attrs  = dep_cmp.get_component_with_attributes_unraveled({})
      this_cmp_attrs = this_cmp.get_component_with_attributes_unraveled({})

      lambda_params.each do |param|
        attributes << get_lambda_param_attribute_value(param[1].to_s, dep_cmp_attrs, this_cmp_attrs, '__')
      end

      attributes
    end

    def self.get_lambda_param_attribute_value(param, dep_cmp_attrs, this_cmp_attrs, delimiter)
      param_cmp, param_attr = param.split(delimiter)

      match_attr =
        if param_cmp.eql?(pretify_cmp_name(dep_cmp_attrs[:component_type]))
          dep_cmp_attrs[:attributes].find{ |attr| (attr[:root_display_name]||attr[:display_name]).eql?(param_attr) }
        elsif param_cmp.eql?('this')
          this_cmp_attrs[:attributes].find{ |attr| (attr[:root_display_name]||attr[:display_name]).eql?(param_attr) }
        else
          fail Error.new("Invalid lambda param specification '#{param}'!")
        end

      match_attr ? match_attr[:value_asserted] : nil
    end

    def self.pretify_cmp_name(cmp_name)
      cmp_name.gsub('__', '_')
    end
  end
end; end
