module XYZ
  class File_assetController < Controller
    helper :i18n_string_mapping

    def get(id)
      file_asset = get_object_by_id(id)
      file_asset[:name] = file_asset[:file_name]

      return {:data=>file_asset}
    end

    def test_get(*path_array)
      path = path_array.join("/")
      repo,af_path = (path =~ Regexp.new("(^[^/]+)/(.+$)"); [$1,$2])
      sp_hash = {
        :filter => [:eq, :path, af_path],
        :cols => [:id,:path,:implementation_info]
      }
      mh  = ModelHandle.new(ret_session_context_id(),:file_asset)
      file_asset = Model.get_objects_from_sp_hash(mh,sp_hash).find{|x|x[:implementation][:repo] == repo}
      raise "file asset #{path} not found" unless file_asset
      pp file_asset
      contents = file_asset.get_content()
      contents.each_line{|l|STDOUT << l}
      STDOUT << "\n"
      {:content=>"<pre>#{contents}</pre>"}
    end
  end
end
