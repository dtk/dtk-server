module Ramaze::Helper
  module RestAsync
    def rest_deferred_response(&blk)
      response_procs = {
        ok: lambda do |data|
          JSON.pretty_generate(rest_ok_response(data))
        end,
        notok: lambda do |error|
          error_hash = ::DTK::RestError.create(error).hash_form()
          JSON.pretty_generate(rest_notok_response(error_hash))
        end
      }
      async_callback = request.env['async.callback']
      content_type = 'text/html'
      ::DTK::AsyncResponse.create(async_callback, content_type, response_procs, &blk)
    end
  end
end
