module XYZ
  module DSConnector
    class UserData < Top
      def get_objects__node(&block)
        data_file_path = APPLICATION_DIR + "/cache/data_source.json" #TODO: stub
        #no op if file does not exsits
        hash = Aux::hash_from_file_with_json(data_file_path)
        return HashMayNotBeComplete.new() if hash.nil?
        #TODO: stub
        HashMayNotBeComplete.new() 
      end
    end
  end
end       
