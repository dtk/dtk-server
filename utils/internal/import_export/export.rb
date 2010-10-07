module XYZ
  #class mixin
  module ExportObject
    #not idempotent
    #target_id_handle_x can either be an id_handle or an array of id_handles
    def export_objects_to_file(target_id_handle_x,json_file,opts={})
      #TODO: more efficient way of doing this since this causes fle to be read multiple times
      if target_id_handle_x.kind_of?(Array)
        fm = "w"
        target_id_handle_x.each do |target_id_handle| 
          opts_x = opts.merge({:file_open_mode => fm})
          opts_x.merge!({:container_uri => target_id_handle[:uri]}) if opts[:nest]
          export_objects_to_file_single_target(target_id_handle,json_file,opts_x)
          fm = "a"
        end
      else
        export_objects_to_file_single_target(target_id_handle_x,json_file,opts)
      end
    end

    def export_objects_to_file_single_target(target_id_handle,json_file,opts={})
      target_id_info = get_row_from_id_handle(target_id_handle)
      raise Error.new("Target given (#{target_id_handle}) does not exist") unless target_id_info
      prefix = nil
      if target_id_info[:uri] =~ %r{(^/.+?/.+?)/.+$}
        prefix = $1 
      elsif target_id_info[:uri] =~ %r{(^/.+/.+$)}
        prefix = $1
      end
      raise Error if prefix.nil?
      get_objs_opts =  {:depth => :deep, :no_hrefs => true, :no_ids => true, :no_top_level_scalars => true, :no_null_cols => true, :fk_as_ref => prefix}.merge(opts)
      objects = get_instance_or_factory(target_id_handle,nil,get_objs_opts)

      #stripping off "key" which would be the containing object
      hash_content = objects.values.first
      #nest if opts[:container_uri] set
      if opts[:container_uri]
        path = opts[:container_uri].gsub(Regexp.new("^/"),"").split("/")
        hash_content = path.reverse.inject(hash_content){|h,key|{key => h}} 
      end
      begin
        f = File.open(json_file,opts[:file_open_mode]||"w")
        f.puts(JSON.pretty_generate(hash_content))
       rescue Exception => err 
        raise Error.new("Error writing exported data to file #{json_file}: #{err}")
       ensure
       	f.close
      end
    end
  end
end
