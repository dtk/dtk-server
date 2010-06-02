module XYZ
  class DataSourceController < Controller
    def create(*uri_array)
      c = ret_session_context_id()
      ds_name = uri_array.shift
      container_id_handle = IDHandle[:c => c, :uri => "/" + uri_array.join("/")]
      DataSource.create(container_id_handle,ds_name)
      "data source created with name #{ds_name}"
    end
  end
end




