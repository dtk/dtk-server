module DTKModule
  class  Ec2::Node
    class Operation
      class IamInstanceProfile < self
        class ClassMethod < OperationBase::ClassMethod
          include Aws::Stdlib::Mixin

          # profile_arn being nil means removes instance profile
          def set_iam_instance_profiles(instance_ids, profile_arn = nil)
            cache_relevant_associations!(instance_ids)
            if profile_arn
              instance_ids.map { |instance_id| associate_iam_instance_profile(instance_id, profile_arn) }
            else
              instance_ids.map { |instance_id| disassociate_iam_instance_profile(instance_id) }
            end
          end
          
          private

          def cache_relevant_associations!(instance_ids)
            @ndx_associations ||= get_ndx_associations(instance_ids) # indexed by instance id
          end

          def association?(instance_id)
            fail "@ndx_associations should be set" if @ndx_associations.nil?
            @ndx_associations[instance_id]
          end

          def associate_iam_instance_profile(instance_id, profile_arn)
            if existing_association = association?(instance_id)
              replace_association(existing_association, profile_arn)
            else
              create_association(instance_id, profile_arn)
            end
          end
          
          def disassociate_iam_instance_profile(instance_id)
            if existing_association = association?(instance_id)
              remove_association(existing_association)
            end
          end

          def create_association(instance_id, profile_arn)
            params = {
              iam_instance_profile: iam_instance_profile_api_param(profile_arn),
              instance_id: instance_id
            }
            client.associate_iam_instance_profile(params)
          end

          def replace_association(existing_association, profile_arn)
            unless existing_association.iam_instance_profile.arn == profile_arn
              params = {
                iam_instance_profile: iam_instance_profile_api_param(profile_arn),
                association_id: existing_association.association_id
              }
              client.replace_iam_instance_profile_association(params)
            end
          end

          def remove_association(existing_association)
            client.disassociate_iam_instance_profile(association_id: existing_association.association_id)
          end

          def get_ndx_associations(instance_ids)
            resp = client.describe_iam_instance_profile_associations(Aux.filter('instance-id', *instance_ids))
            resp.iam_instance_profile_associations.inject({}) { |h, association| h.merge(association.instance_id => association) }
          end
          
          def iam_instance_profile_api_param(profile_arn)
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

