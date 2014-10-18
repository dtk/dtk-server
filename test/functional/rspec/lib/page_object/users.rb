class Users < Main
    
  def click_on_edit_user(user)
    @session.within(:table) do
      @session.find("//tr[td[.=\"#{user}\"]]/td/a/span[.=\"Edit\"]").click
    end
  end

  def assign_user_group_for_user(usergroup)
    @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").click
    @session.check(usergroup)
    @session.find("//div/button[@class = \"multiselect dropdown-toggle btn btn-default\"]").click
  end

  def save_edit_changes
    @session.click_button('Edit User')
  end
end
