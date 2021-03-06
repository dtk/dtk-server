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
  class ComponentOrder < Model
    def self.update_with_applicable_dependencies!(component_deps, component_idhs)
      sample_idh = component_idhs.first
      cols_for_get_virtual_attrs_call = [:component_type, :implementation_id, :extended_base]
      # TODO: switched to use inherited component_order_objs; later will allow component_order_objs directly on component instances and have
      # them override
      # TODO: should also modifying cloning so  component instances not getting the component_order_objs
      sp_hash = {
        #        :cols => [:id,:component_order_objs]+cols_for_get_virtual_attrs_call,
        cols: [:id, :inherited_component_order_objs] + cols_for_get_virtual_attrs_call,
        filter: [:oneof, :id, component_idhs.map(&:get_id)]
      }
      cmps_with_order_info = prune_if_not_applicable(get_objs(sample_idh.createMH, sp_hash))
      # cmps_with_order_info can have a component appear multiple fo each order relation
      update_with_order_info!(component_deps, cmps_with_order_info)
    end

    # assumption that this is called with components having keys :id,:dependencies, :extended_base, :component_type
    # this can be either component template or component instance with :dependencies joined in from associated template
    # TODO: change :component_dependencies to :derived_order -> must chaneg all upstream uses of this return rest too
    def self.get_ndx_cmp_type_and_derived_order(components)
      ret = {}
      return ret if components.empty?
      components.each do |cmp|
        unless pntr = ret[cmp[:id]]
          pntr = ret[cmp[:id]] = { component_type: cmp[:component_type], component_dependencies: [] }
        end
        if cmp[:extended_base]
          pntr[:component_dependencies] << cmp[:extended_base]
        elsif dep_obj = cmp[:dependencies]
          if dep_cmp_type = dep_obj.is_simple_filter_component_type?()
            pntr[:component_dependencies] << dep_cmp_type
          end
        end
      end
      ComponentOrder.update_with_applicable_dependencies!(ret, components.map(&:id_handle).uniq)
    end

    # assumption that this is called with components having keys :id,:dependencies, :extended_base, :component_type
    # this can be either component template or component instance with :dependencies joined in from associated template
    def self.derived_order(components, &block)
      ndx_cmps = components.inject({}) { |h, cmp| h.merge(cmp[:id] => cmp) }
      cmp_deps = get_ndx_cmp_type_and_derived_order(components)
      Task::Action::OnComponent.generate_component_order(cmp_deps).each do |(component_id, _deps)|
        block.call(ndx_cmps[component_id])
      end
    end

    private

    def self.prune_if_not_applicable(cmps_with_order_info)
      ret = []
      return ret if cmps_with_order_info.empty?
      with_conditionals = []
      cmps_with_order_info.each do |cmp|
        order_info = cmp[:component_order]
        if order_info[:conditional]
          with_conditionals << cmp
        else
          ret << cmp
        end
      end
      with_conditionals.empty? ? ret : (prune(with_conditionals) + ret)
    end

    def self.prune(cmps_with_order_info)
      # TODO: stub that just treats very specific form
      # assuming conditional of form :":attribute_value"=>[":eq", ":attribute.<var>", <val>]
      attrs_to_get = {}
      cmps_with_order_info.each do |cmp|
        unexepected_form = true
        cnd = cmp[:component_order][:conditional]
        if cnd.is_a?(Hash) && cnd.keys.first.to_s == ':attribute_value'
          eq_stmt =  cnd.values.first
          if eq_stmt.is_a?(Array) && eq_stmt[0] == ':eq'
            if cnd.values.first[1] =~ /:attribute\.(.+$)/ && eq_stmt[2]
              attr_name = Regexp.last_match(1)
              val = eq_stmt[2]
              unexepected_form = false
              match_cond = [:eq, :attribute_value, val]
              pntr = attrs_to_get[cmp[:id]] ||= { component: cmp, attr_info: [] }
              pntr[:attr_info] << { attr_name: attr_name, match_cond: match_cond, component_order: cmp[:component_order] }
            end
          end
        end
        fail Error.new('Unexpected form') if unexepected_form
      end
      ret = []
      # TODO: more efficienct is getting this in bulk
      attrs_to_get.each do |_cmp_id, info|
        info[:attr_info].each do |attr_info|
          # if component order appears twice then taht means disjunction
          next unless  attr_val_info = info[:component].get_virtual_attribute(attr_info[:attr_name], [:attribute_value])
          # TODO: stubbed form treating
          match_cond = attr_info[:match_cond]
          fail Error.new('Unexpected form') unless match_cond.size == 3 && match_cond[0] == :eq && match_cond[1] == :attribute_value
          if attr_val_info[:attribute_value] == match_cond[2]
            ret << info[:component].merge(component_order: attr_info[:component_order])
          end
        end
      end
      ret
    end
    def self.update_with_order_info!(component_deps, cmps_with_order_info)
      cmps_with_order_info.each do |info|
        pntr = component_deps[info[:id]] ||= { component_type: order_info[:component_type], component_dependencies: [] }
        dep = info[:component_order][:after]
        pntr[:component_dependencies] << dep unless pntr[:component_dependencies].include?(dep)
      end
      component_deps
    end
  end
end