module XYZ
  module ActionSet
    Delim = '__'
  end

  class ActionsetController < MainController
    def process(*route)
      action_set_key = route.join("/").gsub(Regexp.new("/#{ActionSet::Delim}.*$"),"")
      pp [:route_info,R8::Routes[:action_set][action_set_key]]
      "test"
    end
  end

  #enter the routes defined in config into Ramaze
  (R8::Routes[:action_set]||[]).each_key do |route|
    Ramaze::Route["/xyz/#{route}"] = lambda{ |path, request|
      if path =~ Regexp.new("^/xyz/#{route}")
        path.gsub(Regexp.new("^/xyz/#{route}"),"/xyz/actionset/process/#{route}/#{ActionSet::Delim}")
      end
    }
  end
end
