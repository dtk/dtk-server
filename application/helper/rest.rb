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
module Ramaze::Helper
  module Rest
    def rest_response
      unless @ctrl_results.is_a?(BundleAndReturnHelper::ControllerResultsRest)
        fail Error.new("controller results are in wrong form; it should have 'rest' form")
      end

      begin
        JSON.generate(@ctrl_results)
      rescue Exception => ex
        ::DTK::Log.warn "Encoding error has occured, trying to fix it. Error #{ex.class} #{ex.message}"
        JSON.generate DTK::ActionResultsQueue::Result.normalize_data_to_utf8_output!(@ctrl_results)
      end
    end

    # opts can have keys:
    #  :encode_into
    #  :datatype
    #  :info
    #  :warn
    #  :error # TODO: is this possible
    def rest_ok_response(data = nil, opts = {})
      data ||= {}
      if encode_format = opts[:encode_into]
        # This might be a misnomer in taht payload is still a hash which then in RestResponse.new becomes json
        # for case of yaml, the data wil be a string formed by yaml encoding
        data =
          case encode_format
            when :yaml then encode_into_yaml(data)
            else fail Error.new("Unexpected encode format (#{encode_format})")
          end
      end

      payload = { status: :ok, data: data }
      payload.merge!(datatype: opts[:datatype]) if opts[:datatype]

      # set custom messages in response
      [:info, :warn, :error].each do |msg_type|
        payload.merge!(msg_type => opts[msg_type]) if opts[msg_type]
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
      RestResponse.new(status: :notok,
                       validation:           {
            message: message,
            actions_needed: actions_needed
          })
    end

    def rest_notok_response(errors = [{ code: :error }])
      if errors.is_a?(Hash)
        errors = [errors]
      end
      RestResponse.new(status: :notok, errors: errors)
    end

    private

    def encode_into_yaml(data, opts = {})
      data_to_encode = data
      if opts[:remove_null_keys]
        data_to_encode = remove_null_keys(data)
      end
      ::DTK::Aux.serialize(data_to_encode, :yaml) + "\n"
    end

    def remove_null_keys(data)
      if data.is_a?(Hash)
        ret = {}
        data.each_pair { |k, v| ret[k] = remove_null_keys(v) unless v.nil? }
        ret
      elsif data.is_a?(Array)
        data.map { |el| remove_null_keys(el) }
      else
        data
      end
    end

    class RestResponse < Hash
      def initialize(hash)
        replace(hash)
      end

      def is_ok?
        self[:status] == :ok
      end

      def data
        self[:data]
      end
    end
  end
end
