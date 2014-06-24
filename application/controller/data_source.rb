module XYZ
  class DataSourceController < AuthController
    # TBD: just test hard wired to ec2 and
    def create__ec2(*uri_array)
      c = ret_session_context_id()
      ds_name = "ec2"
      container_id_handle = IDHandle[:c => c, :uri => "/" + uri_array.join("/")]
      # TBD stub
      hash_content = {:data_source_object => {"node" => {},"security_group" => {}}}
      DataSource.create(container_id_handle,ds_name,hash_content)
      "data source created with name #{ds_name}"
    end
    def create__chef(*uri_array)
      c = ret_session_context_id()
      ds_name = "chef"
      container_id_handle = IDHandle[:c => c, :uri => "/" + uri_array.join("/")]
      # TBD stub
      hash_content = {:data_source_object => {"component" => {}}}
      DataSource.create(container_id_handle,ds_name,hash_content)
      "data source created with name #{ds_name}"
    end
  end
end




