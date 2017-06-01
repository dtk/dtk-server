module DTKModule
  class  Ec2::Node
    class Operation
      class IamInstanceProfile < self
        class ClassMethod < OperationBase::ClassMethod
          include Aws::Stdlib::Mixin

          def set_iam_instance_profiles(instance_ids, profile_arn)
            set_instance_variables!(instance_ids, profile_arn)
            instance_ids.map { |instance_id| set_iam_instance_profile(instance_id) }
          end
          
          def set_iam_instance_profile(instance_id, profile_arn = nil)
            set_instance_variables!([instance_id], profile_arn)
            if existing_association = ndx_associations[instance_id]
              replace_association(existing_association)
            else
              create_association(instance_id)
            end
          end

          def remove_iam_instance_profile(instance_id)
            set_instance_variables!([instance_id])
            if association = ndx_associations[instance_id]
              client.disassociate_iam_instance_profile(association_id: association.association_id)
            end
          end
          
          private

          attr_reader :profile_arn, :ndx_associations

          def set_instance_variables!(instance_ids, profile_arn = nil)
            @profile_arn      ||= profile_arn
            @ndx_associations ||= get_ndx_associations(instance_ids) # indexed by instance id
          end

          def get_ndx_associations(instance_ids)
            resp = client.describe_iam_instance_profile_associations(Aux.filter('instance-id', *instance_ids))
            resp.iam_instance_profile_associations.inject({}) { |h, association| h.merge(association.instance_id => association) }
          end

          def create_association(instance_id)
            params = {
              iam_instance_profile: iam_instance_profile_api_param,
              instance_id: instance_id
            }
            client.associate_iam_instance_profile(params)
          end

          def replace_association(existing_association)
            unless existing_association.iam_instance_profile.arn == profile_arn
              params = {
                iam_instance_profile: iam_instance_profile_api_param,
                association_id: existing_association.association_id
              }
              client.replace_iam_instance_profile_association(params)
            end
          end

          def iam_instance_profile_api_param
            name = profile_arn.split('/').last
            {
              arn: profile_arn,
              name: name
            }
          end
          
        end
      end
    end
  end
end

