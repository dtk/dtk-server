module XYZ
  #class mixin
  module ExportObject
    #not idempotent
    def export_objects_to_file(target_id_handle,json_file)
      target_id_info = get_row_from_id_handle(target_id_handle)
      raise Error.new("Target given (#{target_id_handle}) does not exist") if target_id_info.nil?
      
      prefix = nil
      if target_id_info[:uri] =~ %r{(^/.+?/.+?)/.+$}
        prefix = $1 
      elsif target_id_info[:uri] =~ %r{(^/.+/.+$)}
        prefix = $1
      end
      raise Error if prefix.nil?
      objects = get_instance_or_factory(target_id_handle,nil,{
           :depth => :deep, :no_hrefs => true, :no_ids => true, :no_top_level_scalars => true, :no_null_cols => true, :fk_as_ref => prefix}) 

      #stripping off "key" which would be the containing object
      hash_content = objects.values.first

      begin
        f = File.open(json_file,"w")
        f.puts(JSON.pretty_generate(hash_content))
       rescue Exception => err 
        raise Error.new("Error writing exported data to file #{json_file}: #{err}")
       ensure
       	f.close
      end
    end
  end
end