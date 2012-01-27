module R8::Client
  class StateChangeCommand < CommandBaseThor
    desc "list","List pending state changes"
    def list()
      get rest_url("state_change/list_pending_changes")
    end
  end
end


