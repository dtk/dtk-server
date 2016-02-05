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
module DTK; class AttributeLink
  class PropagateProcessor
    # TODO: deprecate when remove all references
    module LegacyMixin
      private

      def legacy_internal_hash_form?
        if function.is_a?(String)
          case function
          when 'select_one'
            propagate_when_select_one()
          when 'sap_config__l4'
            propagate_when_sap_config__l4()
          when 'host_address_ipv4'
            propagate_when_host_address_ipv4()
          when 'sap_conn__l4__db'
            propagate_when_sap_conn__l4__db()
          when 'sap_config_conn__db'
            propagate_when_sap_config_conn__db()
          end
        end
      end
      
      # TODO: need to simplify so we dont need all these one ofs
      #######function-specfic propagation
      # TODO: refactor to use  ret_cartesian_product()
      def propagate_when_sap_config__l4
        output_v =
          if output_semantic_type().is_array?
            fail Error::NotImplemented.new('propagate_when_sap_config__l4 when output has empty list') if output_value.empty?
            output_value
          else
            [output_value]
          end
        
        value = nil
        if input_semantic_type().is_array?
          # cartesian product with host_address
          # TODO: may simplify and use flatten form
          value = []
          output_v.each do |sap_config|
            # TODO: euqivalent changes may be needed on other cartesion products: removing this for below          value += input_value.map{|input_item|sap_config.merge("host_address" => input_item["host_address"])}
            value += input_value.map { |iv| iv['host_address'] }.uniq.map { |addr| sap_config.merge('host_address' => addr) }
          end
        else #not input_semantic_type().is_array?
          fail Error.new('propagate_when_sap_config__l4 does not support input scalar and output array with size > 1') if output_value.size > 1
          value = output_v.first.merge('host_address' => input_value['host_address'])
      end
        { value_derived: value }
      end
      
    # TODO: refactor to use  ret_cartesian_product()
      def propagate_when_host_address_ipv4
        output_v =
        if output_semantic_type().is_array?
          fail Error::NotImplemented.new('propagate_when_host_address_ipv4 when output has empty list') if output_value.empty?
          output_value
        else
          [output_value]
        end
        
      value = nil
        if input_semantic_type().is_array?
          # cartesian product with host_address
          value = output_v.map { |host_address| input_value.map { |input_item| input_item.merge('host_address' => host_address) } }.flatten
        else #not input_semantic_type().is_array?
          fail Error.new('propagate_when_host_address_ipv4 does not support input scalar and output array with size > 1') if output_value.size > 1
          value = output_v.first.merge('host_address' => input_value['host_address'])
        end
        { value_derived: value }
      end
      
      def propagate_when_sap_conn__l4__db
        ret_cartesian_product()
      end
      
      def propagate_when_sap_config_conn__db
      ret_cartesian_product()
      end
      
      def propagate_when_select_one
        fail Error::NotImplemented.new('propagate_when_select_one when input has more than one elements') if output_value() && output_value().size > 1
        { value_derived: output_value ? output_value().first : nil }
      end
      
      def ret_cartesian_product
        output_v =
          if output_semantic_type().is_array?
            fail Error::NotImplemented.new('cartesian_product when output has empty list') if output_value.empty?
            output_value
        else
            [output_value]
          end
        
        value = nil
        if input_semantic_type().is_array?
          value = []
        output_v.each do |sap_config|
            value += input_value.map { |input_item| input_item.merge(sap_config) }
          end
        else #not input_semantic_type().is_array?
          fail Error.new('cartesian_product does not support input scalar and output array with size > 1') if output_value.size > 1
          value =  input_value.merge(output_v.first)
        end
        { value_derived: value }
      end
    end
  end
end; end