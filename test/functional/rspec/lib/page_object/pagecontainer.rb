class PageContainer

  attr_accessor :session
  
  def initialize(session)
    @session = session
  end

  def goto_homepage(full_host)
    @session.visit(full_host) 
  end

  def close
    @session.driver.browser.close 
  end
end
