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
  class ServiceNodeBinding
    private

    class Import
      include FactoryObjectMixin
      def initialize(aug_assembly_nodes)
        @aug_assembly_nodes = aug_assembly_nodes
      end

      def import(node_bindings)
        ret = {}
        return ret if (node_bindings || []).empty?

        unless node_bindings.is_a?(Hash)
          fail ErrorIllFormedTerm.new('node bindings', nil, 'is not a hash')
        end
        updates = node_bindings.each do |k, v|
          sub_assembly_node_id, sub_assembly_ref =  find_assembly_node_id_and_ref(k)
          assembly_node_id, assembly_ref = find_assembly_node_id_and_ref(v)
          hash = {
            assembly_node_id: assembly_node_id,
            sub_assembly_node_id: sub_assembly_node_id
          }
          ref = "#{assembly_ref}---#{sub_assembly_ref}"
          ret.merge!(ref => hash)
        end
        ret
      end

      private

      # returns [id,ref]
      def find_assembly_node_id_and_ref(assembly_node_ref)
        assembly_name, node_name = parse_assembly_node_ref(assembly_node_ref)
        match = @aug_assembly_nodes.find do |r|
          r[:assembly][:display_name] == assembly_name && r[:display_name] == node_name
        end
        if match
          ref = assembly_template_node_ref(assembly_name, node_name)
          [match[:id], ref]
        else
          fail ErrorParsing.new("Assembly node ref (#{assembly_node_ref}) does not match any existing assembly node ids")
        end
      end

      # returns [assembly_name,node_name]
      def parse_assembly_node_ref(assembly_node_ref)
        # TODO: should also check that assembly_name is the service add on assembly or sub assembly
        if assembly_node_ref =~ Regexp.new('(^[^/]+)/([^/]+$)')
          [Regexp.last_match(1), Regexp.last_match(2)]
        else
          fail ErrorIllFormedTerm.new('assembly node ref', assembly_node_ref)
        end
      end
    end

    public

    class ErrorParsing < ErrorUsage
    end
    class ErrorIllFormedTerm < ErrorParsing
      def initialize(term, val, alt_descript = nil)
        super(err_msg(term, val, alt_descript))
      end

      private

      def err_msg(term, val, alt_descript)
        last_part =
          if alt_descript then alt_descript
          elsif val.is_a?(String) then "(#{val})"
          else "(#{val.inspect})"
        end
        "Ill-formed #{term} #{last_part}"
      end
    end
  end
end