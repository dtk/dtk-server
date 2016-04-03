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
# TODO: rewrite to use style of vpc_subnet for validate and converge
module DTK
  class CommandAndControlAdapter::Ec2::Reified::Target
    class Component
      class SecurityGroup < self
        Attributes = [:group_name, :id, :vpc_id]
      
        def initialize(reified_target, sg_service_component)
          super(reified_target, sg_service_component)
        end 

        # Returns an array of violations; if no violations [] is returned
        def validate_and_fill_in_values!
          ret = []
          if !id and !group_name
            aug_attrs = get_dtk_aug_attributes(:group_name, :id)
            return [Violation::ReqUnsetAttrs.new(aug_attrs)]
          end
          validate_and_fill_in_values_name_and_id!
        end

        private

        def validate_and_fill_in_values_name_and_id!
          ret = []
          aws_sg_from_id = aws_sg_from_name = nil
          if id
            aws_sg_from_id, violations = validate_group_id
            ret += violations
            if aws_sg_from_id and !group_name
              update_and_propagate_dtk_attributes({group_name: aws_sg_from_id[:name]} , prune_nil_values: true)
            end
          end

          if group_name
            aws_sg_from_name, violations = validate_group_name
            ret += violations
            if aws_sg_from_name and !id
              update_and_propagate_dtk_attributes({id: aws_sg_from_name[:group_id]} , prune_nil_values: true)
            end
          end

          if aws_sg_from_id and aws_sg_from_name
            if aws_sg_from_id[:group_id] != aws_sg_from_name[:group_id]
              # TODO: raise error about conflicting id and name refs
            end
          end
          ret
        end

        # returns [aws_security_group, violations]
        def validate_group_id
          violations = []
          unless aws_security_group = aws_conn.security_group_by_id?(id)
            legal_ids = security_groups_in_vpc.map { |sg| sg[:group_id] }
            violations = [Violation::InvalidSecurityGroup::Id.new(group_id, vpc_id, legal_ids)]
          end
          [aws_security_group, violations]
        end

        # returns [aws_security_group, violations]
        def validate_group_name
          violations = []
          unless aws_security_group = aws_conn.security_group_by_name?(group_name)
            legal_names = security_groups_in_vpc.map { |sg| sg[:name] }
            violations = [Violation::InvalidSecurityGroup::Name.new(group_name, vpc_id, legal_names)]
          end
          [aws_security_group, violations]
        end

        def security_groups_in_vpc
          aws_conn.security_groups(vpc_id: vpc_id)
        end

        def vpc_component
          connected_component(:vpc)
        end

        def aws_conn
          vpc_component.aws_conn
        end

        def validate_group_name_and_set_group_id!
          # TODO: stub
          # use vpc_component.aws_conn
          []
        end
      end
    end
  end
end


