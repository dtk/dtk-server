module XYZ
  #class mixin
  module ImportObject
    #not idempotent
    def import_objects_from_file(target_id_handle,json_file)
      raise Error.new("file given #{json_file} does not exist") unless File.exists?(json_file)
      unless exists? target_id_handle 
        #TBD: assumption is that target_id_handle is in uri form
        create_simple_instance?(target_id_handle[:uri],target_id_handle[:c])
      end

      hash_content = nil
      File.open(json_file) do |f| 
        begin
	  json = f.read
         rescue Exception => err
          raise Error.new("error reading file (#{json_file}): #{err}")
        end
        begin
          hash_content = JSON.parse(json)
         rescue Exception => err
          #use pure json to find parsing error
          require 'json/pure'
          begin 
            JSON::Pure::Parser.new(json).parse
           rescue Exception => detailed_err
            raise Error.new("file (#{json_file} has json parsing error: #{detailed_err}")
          end
        end
      end
      input_into_model(target_id_handle,hash_content)
    end
  end
end

