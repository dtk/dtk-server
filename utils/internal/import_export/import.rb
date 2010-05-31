module XYZ
  #class mixin
  module ImportObject
    #not idempotent
    def import_objects_from_file(target_id_handle,json_file)
      raise Error.new("Target given (#{target_id_handle}) does not exist") unless exists? target_id_handle 
      raise Error.new("file given #{json_file} does not exist") unless File.exists?(json_file)
      hash_content = nil
      File.open(json_file){|f| 
        begin
	  json = f.read
         rescue Exception => err
          raise Error.new("error reading file (#{json_file}): #{err}")
         end
         begin
           hash_content = JSON.parse(json)
          rescue Exception
           raise Error.new("file (#{json_file} has json parsing error")
         end
      }
      input_into_model(target_id_handle,hash_content)
    end
  end
end

