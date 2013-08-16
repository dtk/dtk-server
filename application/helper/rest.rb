module Ramaze::Helper
  module Rest
    def rest_response()
      unless @ctrl_results.kind_of?(BundleAndReturnHelper::ControllerResultsRest)
        raise Error.new("controller results are in wrong form; it should have 'rest' form")
      end
      JSON.generate(@ctrl_results)
    end

    def rest_ok_response(data=nil,opts={})
      data ||= Hash.new
      if encode_format = opts[:encode_into]
        #This might be a misnomer in taht payload is still a hash which then in RestResponse.new becomes json
        #for case of yaml, the data wil be a string formed by yaml encoding
        data = 
          case encode_format
            when :yaml
              ::DTK::Aux.serialize(data,:yaml) + "/n"
            else raise Error.new("Unexpected encode format (#{encode_format})")
          end
      end

      payload = {:status => :ok,:data => data}
      payload.merge!(:datatype => opts[:datatype]) if opts[:datatype]
      RestResponse.new(payload)
    end

    # 
    # Actions needed is Array of Hashes with following attributes:
    #
    # :action => Name of action to be executed
    # :params => Parameters needed to execute that action
    # :wait_for_complete => In case we need to wait for end of that action, type and id
    #                       It will call task_status for given entity.
    # Example:
    #[
    #  :action => :start, 
    #  :params => {:assembly_id => assembly[:id]}, 
    #  :wait_for_complete => {:type => :assembly, :id => assembly[:id]}
    #]

    def rest_validate_response(message, actions_needed)
      RestResponse.new({
        :status => :notok, 
        :validation => 
          { 
            :message => message, 
            :actions_needed => actions_needed
          }
        })
    end

    def rest_notok_response(errors=[{:code => :error}])
      if errors.kind_of?(Hash)
        errors = [errors]
      end
      RestResponse.new(:status => :notok, :errors => errors)
    end

    private
    class RestResponse < Hash
      def initialize(hash)
        replace(hash)
      end
      def is_ok?
        self[:status] == :ok
      end
      def data()
        self[:data]
      end
    end
  end
end
