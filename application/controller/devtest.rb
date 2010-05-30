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
	id_info = IDInfoTable.get_row_from_id_handle id_handle,  :raise_error => true 

	#check if instance or factory
	return get_factory(href_prefix,id_info,opts) if id_info[:is_factory]
	get_instance(href_prefix,id_info,true,opts)      
objs = Object.get_instance_or_factory(IDHandle[:c => c,:uri => uri],href_prefix,opts)
      return @results = objs
require 'pp'; pp objs
#      def get_objects_wrt_parent(relation_type,parent_id_handle,where_clause={})
      @results = objs.map{|o|o.object_slice([:id,:vendor_attributes])}
    end
  end
end
