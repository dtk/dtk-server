# TODO: Marked for removal [Haris]
module XYZ
  class State_changeController < AuthController
    def rest__list_pending_changes(target_id=nil)
      target_idh = target_idh_with_default(target_id)
      rest_ok_response StateChange.list_pending_changes(target_idh)
    end
  end
end
