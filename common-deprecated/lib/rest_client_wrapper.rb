require 'restclient'
require 'json'
module DTK
  module Common
    module Rest
      module ResponseTokens
        StatusOK = "ok"
        StatusNotok = "notok"
        DataField = "data"
        StatusField = "status"
        ErrorsField = "errors"
        ErrorsSubFieldCode = "code"
        GenericError = "error"
      end

      class ClientWrapper 
        class << self
          include ResponseTokens
          def get_raw(url,opts={},&block)
            error_handling(opts) do
              raw_response = ::RestClient::Resource.new(url,opts).get()
              block ? block.call(raw_response) : raw_response
            end
          end

          def get(url,opts={})
            get_raw(url,opts){|raw_response|Response.new(json_parse_if_needed(raw_response))}
          end

          def post_raw(url,body={},opts={},&block)
            error_handling(opts) do
              raw_response = ::RestClient::Resource.new(url,opts).post(body)
              block ? block.call(raw_response) : raw_response
            end
          end

          def post(url,body={},opts={})
            post_raw(url,body,opts){|raw_response|Response.new(json_parse_if_needed(raw_response))}
          end

          def json_parse_if_needed(item)
            item.kind_of?(String) ? JSON.parse(item) : item
          end
          private
          def error_handling(opts={},&block)
            begin
              block.call 
            rescue ::RestClient::InternalServerError,::RestClient::RequestTimeout,Errno::ECONNREFUSED => e
              error_response({ErrorsSubFieldCode => RestClientErrors[e.class.to_s]||GenericError},opts)
            rescue Exception => e
              error_response({ErrorsSubFieldCode => GenericError},opts)
            end
          end 
          def error_response(error_or_errors,opts={})
            errors = error_or_errors.kind_of?(Hash) ? [error_or_errors] : error_or_errors
            (opts[:error_response_class]||ResponseError).new(StatusField => StatusNotok, ErrorsField => errors)
          end

          RestClientErrors = {
            "RestClient::InternalServerError" => "internal_server_error",
            "RestClient::RequestTimeout" => "timeout",
            "Errno::ECONNREFUSED" => "connection_refused"
          }
        end
      end

      class Response < Hash
        include ResponseTokens
        def initialize(hash={})
          super()
          replace(hash)
        end
        def ok?()
          self[StatusField] == StatusOK
        end

        def data()
          self[DataField]
        end
      end

      module ResponseErrorMixin
        def ok?()
          false
        end
      end
      class ResponseError < Response
        include ResponseErrorMixin
        def initialize(hash={})
          super(hash)
        end
      end
    end
  end
end

