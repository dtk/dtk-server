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
      objs = Object.get_instance_or_factory(IDHandle[:c => c,:uri => uri],href_prefix,opts)
      return @results = objs
require 'pp'; pp objs
#      def get_objects_wrt_parent(relation_type,parent_id_handle,where_clause={})
      @results = objs.map{|o|o.object_slice([:id,:vendor_attributes])}
    end
  end
end
