module XYZ
  class File_assetController < AuthController
    helper :i18n_string_mapping

    def get(id)
      file_asset = get_object_by_id(id)
      file_asset[:name] = file_asset[:file_name]

      file_asset[:content] = file_asset.get_content()
      file_asset[:content] ||= 'ERROR RETRIEVING CONTENT'
=begin TODO FOR debugging
      file_asset = {}
      file_asset[:content] = 'this is some stubbed file content to return something---'+id.to_s
=end
      return {:data=>file_asset}
    end

    def save_content()
#      file_asset = get_object_by_id(id)
#      file_asset.update_content(request.params["content"])
      raise Error.new("no file id given") unless request.params["editor_file_id"]
      file_asset = get_object_by_id(request.params["editor_file_id"])
      file_asset.update_content(request.params["editor_file_content"])

      return {:data=>{}}
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

    def test_add(*path_array)
      path = path_array.join("/")
      repo,af_path = (path =~ Regexp.new("(^[^/]+)/(.+$)"); [$1,$2])
      sp_hash = {
        :filter => [:eq, :ref, repo],
        :cols => [:id,:type]
      }
      mh  = ModelHandle.new(ret_session_context_id(),:implementation)
      impl = Model.get_objects_from_sp_hash(mh,sp_hash).first
      raise "implementation #{repo} not found" unless impl
      impl.add_asset_file(af_path)
      {:content => nil}
    end
  end
end
