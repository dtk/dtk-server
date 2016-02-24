require 'singleton'

class Configuration
	include Singleton

  attr_accessor :host, :browser, :username, :password, :headless, :poltergeist, :repoman_user, :parallel, :port_number

  def intialize(port)
    @port_number = port
  end
end
