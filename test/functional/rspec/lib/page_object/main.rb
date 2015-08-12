class Main < PageContainer

  INPUT_SELECTOR="//input[@class='btn btn-success']"
  BUTTON_SELECTOR="//button[@class='btn btn-primary']"


  def on_create_page?
    @session.has_selector?(INPUT_SELECTOR) && @session.find(INPUT_SELECTOR).value.include?("Create") 
  end

  def on_edit_page?
    @session.has_selector?(INPUT_SELECTOR) && @session.find(INPUT_SELECTOR).value.include?("Edit") 
  end

  def press_create_button
    if Capybara.current_driver == :webkit || Capybara.current_driver == :poltergeist
      @session.find(INPUT_SELECTOR).trigger("click")
    else
      @session.find(INPUT_SELECTOR).click
    end
  end

  def press_edit_button
    if Capybara.current_driver == :webkit || Capybara.current_driver == :poltergeist
      @session.find(INPUT_SELECTOR).trigger("click")
    else
      @session.find(INPUT_SELECTOR).click
    end
  end

  def open_create_page
    if Capybara.current_driver == :webkit || Capybara.current_driver == :poltergeist
      @session.find(BUTTON_SELECTOR).trigger("click")
    else
      @session.find(BUTTON_SELECTOR).click
    end
  end

  def open_edit_page(name)
    @session.within(row_selector(name)) do
      @session.click_link('Edit')
    end
  end

  def row_selector(name)
    return "//div[@class='container']/table//tr[td[text()='#{name}']]"
  end

  def press_delete_link(name)
    @session.within(row_selector(name)) do
      @session.click_link('Delete')
    end
    sleep 1
    if Capybara.current_driver == :webkit || Capybara.current_driver == :poltergeist
      @session.driver.alert_messages.last
    else
      @session.driver.browser.switch_to.alert.accept
    end
  end

  def search_for_object(name)
    @session.fill_in('Search', :with => name + "\n")
  end

  def object_exists?(name)
    @session.has_selector?(row_selector(name))
  end

  def enter_data(data, edit=false)
  end

  def get_table_row_data(name) 

  end



  def get_usergroups
    Usergroups.new(@session)
  end

  def get_users
    Users.new(@session)
  end

  def get_namespaces
    Namespaces.new(@session)
  end

  def get_modules
    Modules.new(@session)
  end
end
