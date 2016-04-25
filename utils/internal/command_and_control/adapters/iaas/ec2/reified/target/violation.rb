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

module DTK; class CommandAndControlAdapter::Ec2
  module Reified
    class Target
      class Violation < Reified::Violation
        
        class InvalidCredentials < self
          include Reified::Violation::CommonMixin
          def initialize(reified_component, *attribute_names)
            @attribute_names    = attribute_names
            @attrs              = get_sorted_dtk_aug_attributes(reified_component, *attribute_names)
            @print_level        = :component
            @attr_display_names = @attrs.map { |attr| attr_display_name(attr, @print_level) }
            # TODO: parameterize by component title when have multiple credentials in target
          end

          def fix_text(attr_display_name)
            "Enter value for attribute '#{attr_display_name}'"
          end
          
          def hash_form
            hash_form_multiple_attrs(@attrs, @attr_display_names, :required_unset_attribute)
          end

          def description(_opts = {})
            attrs_ref = @attribute_names.join(', ')
            "One or both of the AWS credentials (#{attrs_ref}) are invalid"
          end
        end

        class InvalidKeypair < IllegalAttrValue
          def initialize(reified_component, attribute_name, value, opts = {})
            super
            @region = opts[:region]
          end

          # opts can have keys
          #   :summary - Boolean
          def description(opts = {})
            if @legal_values.empty?
              "There are no keypairs configured in region '#{@region}'"
            else
              ret = "The name '#{@value}' is not a legal keypair in region '#{@region}'"
              ret << "; legal values are: #{@legal_values.join(', ')}" unless opts[:summary]
              ret
            end
          end
        end
        

        # TODO: DTK-2525; got here in refining the violations to work with fix wizard
        
        class InvalidSecurityGroup < self
          class Id < self
            def initialize(id, vpc_id, legal_ids)
              super(:id, id, vpc_id, legal_ids)
            end
          end
          
          class Name < self
            def initialize(name, vpc_id, legal_names)
              super(:name, name, vpc_id, legal_names)
            end
          end

          def initialize(type, name_or_id, vpc_id, legal_items)
            @type        = type
            @name_or_id  =  name_or_id
            @vpc_id      = vpc_id
            @legal_items = legal_items
          end
          private :initialize

          def description
            if @legal_items.empty?
              "There are no #{type_ref}s configured in vpc '#{@vpc_id}'"
            else
              "The name '#{@name_or_id}' is not a legal #{type_ref} in vpc '#{@vpc_id}'; legal values are: #{@legal_items.join(', ')}" 
            end
          end
          def type
            "invalid_security_group_#{@type}".to_sym
          end
          
          private
          
          def type_ref
            "security group #{@type}"
          end
        end
        
      end
    end
  end
end; end

