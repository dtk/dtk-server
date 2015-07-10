require 'singleton'

class Configuration
  include Singleton
  attr_accessor :host, :browser, :username, :password, :headless
end
