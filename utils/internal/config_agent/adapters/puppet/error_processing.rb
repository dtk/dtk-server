module XYZ
  module PuppetErrorProcessing
    #tries to normalize error received from node
    def interpret_error(error_in_result,components)
      ret = error_in_result
      source = error_in_result["source"]
      #working under assumption that stage assignment same as order in components
      if source =~ Regexp.new("^/Stage\\[([0-9]+)\\]")
        index = ($1.to_i) -1
        if cmp_with_error = components[index]
          ret = error_in_result.inject({}) do |h,(k,v)|
            ["source","tags","time"].include?(k) ? h : h.merge(k => v)
          end
          if cmp_name = cmp_with_error[:display_name]
            ret.merge!("component" => cmp_name)
          end
        end
      end
      ret
    end
  end
end
