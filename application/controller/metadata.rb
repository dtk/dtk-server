module XYZ
  class MetadataController < Controller
    def rest__get_metadata
      metadata_file = ret_non_null_request_params(:metadata_file)
      file = File.open(File.expand_path("../meta/tables_metadata/#{metadata_file}.json", File.dirname(__FILE__))).read
      rest_ok_response file
    end
  end
end
