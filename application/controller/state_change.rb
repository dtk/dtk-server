module XYZ
  class State_changeController < Controller
    def rest__list()
      super_ret = super
      if super_ret.is_ok?()
        data = super_ret.data
        #To reflect that node may have changed names
        StateChange.update_with_current_names!(data)
        rest_ok_response data
      else
        super_ret
      end
    end
  end
end
