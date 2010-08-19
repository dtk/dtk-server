module XYZ
  class ActionsetController < MainController
    def process(*route)
      pp route
      "test"
    end
  end
end

#enter the routes defined in config into Ramaze
(R8::Routes[:action_set]||[]).each_key do |route|
  Ramaze::Route["/xyz/#{route}"] = lambda{ |path, request|
    if path =~ Regexp.new("^/xyz/#{route}")
      path.gsub(/xyz/,"xyz/actionset/process")
    end
  }
end
