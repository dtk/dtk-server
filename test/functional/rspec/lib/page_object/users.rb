class Users < Main
    
  def click_on_edit_user(user)
    @session.within(:table) do
      @session.find("//tr[td[.=\"#{user}\"]]/td/a/span[.=\"Edit\"]").click
    end
  end

  def assign_user_group_for_user(usergroup)
    @session.select(usergroup, :from => "repo_client_dtk_open_struct_user_group_ids")
  end

  def save_edit_changes
    @session.click_button('Edit User')
  end
end
