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
  class Assembly::Instance
    class Violations < ::Array
      # each element of violations_array is an array;
      def initialize(violations)
        super()
        # using description to determine uniqueness
        # TODO: use this as fallback and have each viol type have its own uniq compare fn
        violations.inject({}) { |h, viol| h.merge( viol.description => viol) }.each_value { |uniq_viol| self << uniq_viol }
      end

      def table_form
        sort(map { |viol| [viol, viol.table_form] })
      end

      def hash_form
        sort(map { |viol| [viol, viol.hash_form] })
      end

      private

      def sort(viol_output_pairs)
        # sort is so that violations that can affect others (i.e., correction of them can cause other to be solved (e.g., component connection for unset attrs)
        viol_output_pairs.sort { |a, b| Violation.compare_for_sort(a[0], b[0]) }.map { |pairs| pairs[1] }
      end
    end

    module ViolationsMixin
      def find_violations
        nodes_and_cmps = get_info__flat_list(detail_level: 'components').select { |r| r[:nested_component] }
        cmps = nodes_and_cmps.map { |r| r[:nested_component] }

        unset_attr_viols        = find_violations__unset_attrs
        cmp_constraint_viols    = find_violations__cmp_constraints(nodes_and_cmps, cmps.map(&:id_handle))
        cmp_parsing_errors      = find_violations__cmp_parsing_error(cmps)
        unconn_req_service_refs = find_violations__unconn_req_service_refs
        Violations.new(unset_attr_viols + cmp_constraint_viols + unconn_req_service_refs + cmp_parsing_errors)
      end

      private

      def find_violations__unset_attrs
        filter_proc    = lambda { |a| a.required_unset_attribute? }
        assembly_attrs = get_assembly_level_attributes(filter_proc)
        attr_link_mh   = model_handle.createMH(:attribute_link)
        assembly_attrs.reject! { |r_attr| !AttributeLink.get_augmented(attr_link_mh, [:eq, :input_id, r_attr[:id]]).empty? }
        assembly_attr_viols = assembly_attrs.map { |a| Violation::ReqUnsetAttr.new(a, :assembly) }

        filter_proc = lambda { |r| r[:attribute].required_unset_attribute? }
        component_attrs = get_augmented_component_attributes(filter_proc)
        component_attrs.reject! { |r_attr| !AttributeLink.get_augmented(attr_link_mh, [:eq, :input_id, r_attr[:id]]).empty? }
        component_attr_viols = component_attrs.map { |a| Violation::ReqUnsetAttr.new(a, :component) }
        assembly_attr_viols + component_attr_viols
      end

      def find_violations__cmp_constraints(nodes_and_cmps, cmp_idhs)
        ret = []
        return ret if cmp_idhs.empty?
        ndx_constraints = Component.get_ndx_constraints(cmp_idhs, when_evaluated: :after_cmp_added)
        # TODO: this is expensive in that it makes query for each constraint
        nodes_and_cmps.each do |r|
          if constraint_info = ndx_constraints[r[:nested_component][:id]]
            constraint_scope = { 'target_node_id_handle' => r[:node].id_handle }
            constraint_info[:constraints].each do |constraint|
              unless constraint.evaluate_given_target(constraint_scope)
                ret << Violation::ComponentConstraint.new(constraint, r[:node])
              end
            end
          end
        end
        ret
      end

      def find_violations__unconn_req_service_refs
        ret = []
        get_augmented_ports(mark_unconnected: true).each do |aug_port|
          if aug_port[:unconnected] && aug_port[:link_def][:required]
            ret << Violation::UnconnReqServiceRef.new(aug_port)
          end
        end
        ret
      end

      def find_violations__cmp_parsing_error(cmps)
        ret = []
        return ret if cmps.empty?

        cmps.each do |cmp|
          cmp_module_branch = get_parsed_info(cmp[:module_branch_id], 'ComponentBranch')
          if cmp_module_branch && cmp_module_branch[:component_module]
            ret << Violation::ComponentParsingError.new(cmp_module_branch[:component_module][:display_name], 'Component') unless cmp_module_branch[:dsl_parsed]
          end
        end

        if service_module_branch = get_parsed_info(self[:module_branch_id], 'ServiceBranch')
          ret << Violation::ComponentParsingError.new(service_module_branch[:service_module][:display_name], 'Service') unless service_module_branch[:dsl_parsed]
        end

        # if module_branch belongs to service instance assembly_module_version? will not be nil
        service_instance_branch = get_service_instance_branch
        if service_instance_branch && service_instance_branch.assembly_module_version?
          # add violation if module_branch[:dsl_parsed] == false
          ret << Violation::ComponentParsingError.new(self[:display_name], 'Service instance') unless service_instance_branch[:dsl_parsed]
        end

        ret
      end

      def get_parsed_info(module_branch_id, type)
        ret = nil
        cols = [:id, :type, :component_id, :service_id, :dsl_parsed]

        if type.to_s.eql?('ComponentBranch')
          cols << :component_module_info
        elsif type.to_s.eql?('ServiceBranch')
          cols << :service_module
        end

        sp_hash = {
          cols: cols,
          filter: [:eq, :id, module_branch_id]
        }
        unless branch = Model.get_obj(model_handle(:module_branch), sp_hash)
          return ret
        end

        return branch if type.to_s.eql?('ComponentBranch') || type.to_s.eql?('ServiceBranch')

        if (type == 'Component')
          sp_cmp_hash = {
            cols: [:id, :display_name, :dsl_parsed],
            filter: [:eq, :id, branch[:component_id]]
          }
          Model.get_obj(model_handle(:component_module), sp_cmp_hash)
        else
          sp_cmp_hash = {
            cols: [:id, :display_name, :dsl_parsed],
            filter: [:eq, :id, branch[:service_id]]
          }
          Model.get_obj(model_handle(:service_module), sp_cmp_hash)
        end
      end
    end
  end
end
