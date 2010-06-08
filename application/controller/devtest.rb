module XYZ
  class DevtestController < Controller
    def discover_and_update_nodes(*uri_array)
      c = ret_session_context_id()
      ds_type = uri_array.pop.to_sym
      container_uri = "/" + uri_array.join("/")
      ds_uri =  "#{container_uri}/data_source/#{ds_type}"
      ds_id_handle = IDHandle[:c => c, :uri => ds_uri]
      ds_object_objs = Object.get_objects_wrt_parent(:data_source_entry,ds_id_handle)
      raise Error.new("cannot find any #{ds_type} data source objects in #{container_uri}") if ds_object_objs.empty?
      ds_object_objs.each{|x|x.discover_and_update()}
      "discover and update nodes from #{ds_type}"
    end

    #TBD: these are just hacks that are largely cut and paste
    def discover_and_update_components(*uri_array)
      c = ret_session_context_id()
      ds_type = uri_array.pop.to_sym
      container_uri = "/" + uri_array.join("/")
      ds_object_uri =  "#{container_uri}/data_source/#{ds_type}/data_source_entry/component"
      ds_object_id_handle = IDHandle[:c => c, :uri => ds_object_uri]
      ds_object_obj = Object.get_object(IDHandle[:c => c, :uri => ds_object_uri])
      raise Error.new("cannot find any #{ds_type} data source objects in #{container_uri}") if ds_object_obj.nil?
      ds_object_obj.discover_and_update()
      "discover and update components from #{ds_type}"
    end

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
      objs = Object.get_instance_or_factory(IDHandle[:c => c,:uri => uri],href_prefix,opts)
require 'pp'; pp objs
      #TBD: implement :normalized_attrs_only flag
      @results = objs
    end
  end
end
