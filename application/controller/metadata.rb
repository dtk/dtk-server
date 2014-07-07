module XYZ
  class MetadataController < Controller
  	def rest__get_metadata(file_name)
  		file = File.open(File.expand_path("../meta/tables_metadata/#{file_name}.json", File.dirname(__FILE__))).read
      rest_ok_response file
  	end
  end
end