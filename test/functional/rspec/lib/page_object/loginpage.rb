class LoginPage < PageContainer
  def login_user(username, password)
   @session.fill_in('username', with: username)
   @session.fill_in('password', with: password)
   @session.click_button('Log In')
  end

  def logout_user
    @session.click_link('Log Out')
    @session.find("//div/legend[.=\"DTK Admin Panel\"]")
  end
end
