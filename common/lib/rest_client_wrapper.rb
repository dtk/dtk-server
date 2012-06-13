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
        def error_response(error_or_errors)
          errors = error_or_errors.kind_of?(Hash) ? [error_or_errors] : error_or_errors
          ResponseError.new(StatusField => StatusNotok, ErrorsField => errors)
        end
      end

      class ClientWrapper 
        class << self
          include ResponseTokens
          def get_raw(url,opts={},&block)
            error_handling do
              raw_response = ::RestClient::Resource.new(url,opts).get()
              block ? block.call(raw_response) : raw_response
            end
          end

          def get(url,opts={})
            get_raw(url,opts){|raw_response|Response.new(json_parse_if_needed(raw_response))}
          end

          def post_raw(url,body={},opts={},&block)
            error_handling do
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
          def error_handling(&block)
            begin
              block.call 
            rescue ::RestClient::InternalServerError,::RestClient::RequestTimeout,Errno::ECONNREFUSED => e
              error_response(ErrorsSubFieldCode => RestClientErrors[e.class.to_s]||GenericError)
            rescue Exception => e
              error_response(ErrorsSubFieldCode => GenericError)
            end
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

      class ResponseError < Response
        def initialize(hash={})
          super(hash)
        end
        def ok?()
          false
        end
      end
    end
  end
end

