module DTKModule
  class Ec2::Node::Operation
    class Create
      module AwsForm
        REQUIRED_EXPLICITLY = [:image_id, :instance_type, :security_group_ids, :subnet_id, :client_token]
        REQUIRED_FOR_DERIVED = [:count]
        DERIVED = {
          min_count: lambda { |_params| 1 }, 
          max_count: lambda { |params| params[:count] } 
        }
        OPTIONAL_STANDARD_PROCEESSING = [:key_name]
        # special processing for :tags, :user_data
        def self.map(params = {})
          [required(params), optional(params), UserData.aws_form?(params)].compact.inject({}) { |r, h| r.merge(h) }
        end
        
        private
        
        def self.required(params = {})
          ret = matching_keys(REQUIRED_EXPLICITLY, params)
          missing = (REQUIRED_EXPLICITLY - ret.keys) + (REQUIRED_FOR_DERIVED - params.keys)
          raise_mssing_error(missing_attributes) unless missing.empty?
          ret = DERIVED.inject(ret) { |h, (k, fn)| h.merge(k => fn.call(params)) }
        end
        
        def self.optional(params = {})
          matching_keys(OPTIONAL_STANDARD_PROCEESSING, params)
        end
        
        def self.matching_keys(keys, params = {})
          keys.inject({}) { |h, key| params.has_key?(key) ? h.merge(key => params[key]) : h }
        end
        
        def self.raise_mssing_error(missing_attributes)
          if missing_attributes.size == 1
            fail "The attribute '#{missing_attributes.first}' is missing for aws create instance call"
          else
            fail "The attributes (#{missing_attributes.join(', ')}) are missing for aws create instance call"
          end
        end
        
      end
    end
  end
end
