module XYZ
  class DevtestController < Controller
    def list(*uri_array)
      error_405 unless request.get?
      uri = "/" + uri_array.join("/")
      opts = ret_parsed_query_string()
      opts[:no_hrefs] ||= true
      opts[:depth] ||= :deep
      opts[:no_null_cols] = true
      href_prefix = "http://" + http_host() + "/list" 
      c = ret_session_context_id()
      @title = uri
      id_handle = IDHandle[:c => c,:uri => uri]
#      objs = Object.get_instance_or_factory(IDHandle[:c => c,:uri => uri],href_prefix,opts)
require 'pp'; pp objs
      #TBD: implement :normalized_attrs_only flag
      @results = objs
    end
  end
end
