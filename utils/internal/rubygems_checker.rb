module DTK
  class RubyGemsChecker
    def self.gem_exists?(name, version)
      begin
        response_raw = Common::Response::RestClientWrapper.get_raw "http://rubygems.org/api/v1/versions/#{name}.json"
        response = JSON.parse(response_raw)
        matched = response.select {|v| v["number"] == version}
        return matched != []
      rescue Exception => e
        Log.error "We were not able to check if the specified gem exists, reason: #{e.message}"
        return false
      end
    end
  end
end
