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
      payload = {:status => :ok,:data => data}
      if opts[:datatype]
        payload.merge!(:datatype => opts[:datatype])
      end
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
