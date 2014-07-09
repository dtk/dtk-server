class HomePage < PageContainer

  attr_accessor :host_url

  def get_loginpage
    return LoginPage.new(@session)
  end

  def get_header
    return Header.new(@session)
  end
  
  def get_main
    return Main.new(@session)
  end
end