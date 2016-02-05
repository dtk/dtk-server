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
module DTK; class Dependency
  class Simple < All
    def initialize(dependency_obj, node)
      super()
      @dependency_obj = dependency_obj
      @node = node
     end

    # TODO: Marked for removal [Haris]
    def self.create_dependency?(cmp_template, antec_cmp_template, opts = {})
      ret = {}
      unless dependency_exists?(cmp_template, antec_cmp_template)
        create_dependency(cmp_template, antec_cmp_template, opts)
      end
      ret
    end

    def self.create_dependency(cmp_template, antec_cmp_template, _opts = {})
      antec_cmp_template.update_object!(:display_name, :component_type)
      search_pattern = {
        ':filter' => [':eq', ':component_type', antec_cmp_template[:component_type]]
      }
      create_row = {
        ref: antec_cmp_template[:component_type],
        component_component_id: cmp_template.id(),
        description: "#{antec_cmp_template.component_type_print_form()} is required for #{cmp_template.component_type_print_form()}",
        search_pattern: search_pattern,
        type: 'component',
        severity: 'warning'
      }
      dep_mh = cmp_template.model_handle().create_childMH(:dependency)
      Model.create_from_row(dep_mh, create_row, convert: true, returning_sql_cols: create_or_exists_cols())
    end
    class << self
      private

      def dependency_exists?(cmp_template, antec_cmp_template)
        sp_hash = {
          cols: create_or_exists_cols(),
          filter: [:and, [:eq, :component_component_id, cmp_template.id()],
                   [:eq, :ref, antec_cmp_template.get_field?(:component_type)]]
        }
        Model.get_obj(cmp_template.model_handle(:dependency), sp_hash)
      end

      def create_or_exists_cols
        [:id, :group_id, :component_component_id, :search_pattern, :type, :description, :severity]
      end
    end

    def depends_on_print_form?
      if cmp_type = @dependency_obj.is_simple_filter_component_type?()
        Component.component_type_print_form(cmp_type)
      end
    end

    def self.augment_component_instances!(components, opts = Opts.new)
      return components if components.empty?
      sp_hash = {
        cols: [:id, :group_id, :component_component_id, :search_pattern, :type, :description, :severity],
        filter: [:oneof, :component_component_id, components.map(&:id)]
      }
      dep_mh = components.first.model_handle(:dependency)

      dep_objs = Model.get_objs(dep_mh, sp_hash)
      return components if dep_objs.empty?

      simple_deps = []
      ndx_components = components.inject({}) { |h, cmp| h.merge(cmp[:id] => cmp) }
      dep_objs.each do |dep_obj|
        cmp = ndx_components[dep_obj[:component_component_id]]
        dep = new(dep_obj, cmp[:node])
        simple_deps << dep
        (cmp[:dependencies] ||= []) << dep
      end
      if opts[:ret_statisfied_by] and not simple_deps.empty?()
        satisify_cmps = get_components_that_satisify_deps(simple_deps)

        unless satisify_cmps.empty?
          simple_deps.each { |simple_dep| simple_dep.set_satisfied_by_component_ids?(satisify_cmps) }
        end
      end
      components
    end

    def set_satisfied_by_component_ids?(satisify_cmps)
      match_cmp = satisify_cmps.find do |cmp|
        (cmp[:node_node_id] == @node[:id]) && @dependency_obj.component_satisfies_dependency?(cmp)
      end
      @satisfied_by_component_ids << match_cmp.id() if match_cmp
    end

    attr_reader :dependency_obj, :node

    private

    def self.get_components_that_satisify_deps(dep_list)
      ret = []
      query_disjuncts = dep_list.map do |simple_dep|
        dep_obj = simple_dep.dependency_obj
        if filter = dep_obj.simple_filter_triplet?()
          [:and, [:eq, :node_node_id, simple_dep.node.id()], filter]
        else
          Log.error("Ignoring a simple dependency that is not a simple filter (#{simple_dep.dependency_obj})")
          nil
        end
      end.compact
      if query_disjuncts.empty?
        return ret
      end
      cmp_mh = dep_list.first.node.model_handle(:component)
      filter = (query_disjuncts.size == 1 ? query_disjuncts.first : [:or] + query_disjuncts)
      sp_hash = {
        cols: [:id, :group_id, :display_name, :component_type, :node_node_id],
        filter: filter
      }
      Model.get_objs(cmp_mh, sp_hash)
    end
  end
end; end