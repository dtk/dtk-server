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
    class Violation
      def  table_form
        { type: type, description: description }
      end

      # must be overwritten
      def hash_form
        fail Error, "Missing method '#{self.class}#hash_form'"
      end
      # could be overwritten
      def type
        Aux.underscore(Aux.demodulize(self.class.to_s)).to_sym
      end

      private

      def attr_display_name(attr, print_level = :component)
        attr.print_form(Opts.new(level: print_level, convert_node_component: true))[:display_name]
      end

      def hash_remove_nils(hash)
        hash.inject({}) { |h, (k, v)| v.nil? ? h : h.merge(k => v) }
      end

      def attribute_ref
        attr_display_name(@attr, @print_level)
      end

      class ReqUnsetAttr < self
        def initialize(attr, print_level)
          @attr        = attr
          @print_level = print_level
        end

        def type
          :required_unset_attribute
        end

        def hash_form
          { attribute_ref: attribute_ref }
        end

        def description
          "Attribute (#{attr_display_name(@attr, @print_level)}) is required, but unset"
        end
      end

      class ReqUnsetAttrs < self
        def initialize(attrs, print_level)
          opts_print = Opts.new(level: print_level)
          @attr_display_names = attrs.map { |attr| attr_display_name(attr, print_level) }
        end

        def type
          :required_unset_attributes
        end

        def description
          aug_attrs_print_form = @attr_display_names.join(', ')
          "At least one of the attributes (#{aug_attrs_print_form}) is required to be set"
        end
      end

      class IllegalAttrValue < self
        # opts can have keys
        #  legal_values
        def initialize(attr, value, opts = {})
          @attr         = attr
          @value        = value
          @legal_values = opts[:legal_values]
        end

        def type
          :illegal_attribute_value
        end

        def hash_form
          hash_remove_nils(attribute_ref: attribute_ref, value: @value, legal_values: @legal_values)
        end

        def description
          ret = "Attribute '#{attr_display_name(@attr)}' has illegal value '#{@value}'"
          ret << "; legal values are: #{@legal_values.join(', ')}" if @legal_values
          ret
        end
      end


      class TargetServiceCmpsMissing < self
        def initialize(component_types)
          @component_types = component_types
        end
        
        def type
          :target_service_cmps_missing
        end
        
        def description
          cmp_or_cmps = (@component_types.size == 1) ? 'Component' : 'Components'
          is_are = (@component_types.size == 1) ? 'is' : 'are'
          
          "#{cmp_or_cmps} of type (#{@component_types.join(', ')}) #{is_are} missing and #{is_are} required for a target service instance"
        end
      end

      class ComponentConstraint < self
        def initialize(constraint, node)
          @constraint = constraint
          @node = node
        end

        def type
          :component_constraint
        end

        def description
          "On assembly node (#{@node[:display_name]}): #{@constraint[:description]}"
        end
      end

      class UnconnReqServiceRef < self
        def initialize(aug_port)
          @augmented_port = aug_port
        end

        def type
          :unmet_dependency
        end

        def description
          "Component (#{@augmented_port.display_name_print_form()}) has an unmet dependency"
        end
      end

      class ComponentParsingError < self
        def initialize(component, type)
          @component = component
          @type = type
        end

        def type
          :parsing_error
        end

        def description
          "#{@type} module '#{@component}' has one or more parsing errors."
        end
      end

      class MissingIncludedModule < self
        def initialize(included_module, namespace, version = nil)
          @included_module = included_module
          @namespace = namespace
          @version = version
        end

        def type
          :missing_included_module
        end

        def description
          full_name = "#{@namespace}:#{@included_module}"
          "Module '#{full_name}#{@version.nil? ? '' : '-' + @version}' is included in dsl, but not installed. Use 'print-includes' to see more details."
        end
      end

      class MultipleNamespacesIncluded < self
        def initialize(included_module, namespaces)
          @included_module = included_module
          @namespaces = namespaces
        end

        def type
          :mapped_to_multiple_namespaces
        end

        def description
          "Module '#{@included_module}' included in dsl is mapped to multiple namespaces: #{@namespaces.join(', ')}. Use 'print-includes' to see more details."
        end
      end

      class HasItselfAsDependency < self
        def initialize(message)
          @message = message
        end

        def type
          :has_itself_as_dependency
        end

        def description
          @message
        end
      end

      class NodesLimitExceeded < self
        def initialize(new_nodes, running, node_limit)
          @new        = new_nodes
          @running    = running
          @node_limit = node_limit
        end

        def type
          :nodes_limit_exceeded
        end

        def description
          "There are #{@running} nodes currently running in builtin target. Unable to create #{@new} new nodes because it will exceed number of nodes allowed in builtin target (#{@node_limit})"
        end
      end
    end
  end
end
