class HomePage < PageContainer
  attr_accessor :host_url

  def get_loginpage
    LoginPage.new(@session)
  end

  def get_header
    Header.new(@session)
  end

  def get_main
    Main.new(@session)
  end
end
