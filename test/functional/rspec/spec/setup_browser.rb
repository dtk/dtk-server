require 'rubygems'
require 'rspec'
require 'yaml'
require 'require_all'

# Capybara configuration
require 'capybara/rspec'
require 'capybara-webkit'
require_all './lib/page_object/'
Capybara.default_selector = :xpath

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.before(:all) do
    conf = load_configs
    if conf.headless
      load_headless(conf.host)
    else
      puts "Host: #{conf.host}"
      puts "Browser: #{conf.browser}"
      load_browser(conf.host,conf.browser)
    end
  end
end

def load_configs
  rspec_file = '.rspec' 
  env = nil
  File.open(rspec_file).each do |line|
    if (line.match('--options\s?.+_ENV'))
     line.slice!('--options ')
     env = line.strip
    end
  end
  puts "Loading RSpec configuration for: " + env
  full_config = YAML::load(File.open('./config/config.yml'))
  puts "RSpec configuration: " + full_config[env].to_s

  conf = Configuration.instance
  conf.host = full_config[env]["environment"]["full_host"]
  conf.browser = full_config[env]["target"]["browser"]
  conf.username = full_config[env]["account"]["username"]
  conf.password = full_config[env]["account"]["password"]
  conf.headless = full_config[env]["headless"]
  return conf
end

def load_headless(full_host)
  require 'headless'
  puts "Initializing browser, HEADLESS mode"
  Capybara.default_driver = :webkit
  headless = Headless.new
  headless.start
  session = Capybara::Session.new :webkit
  @homepage = HomePage.new(session)
  @homepage.goto_homepage(full_host)
  puts "Opening home page: " + full_host
  return @homepage
end

def load_browser(full_host, target_browser)
  puts "Initializing browser " + target_browser.to_s
  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(app, :browser => target_browser.to_sym)
  end
  Capybara.current_driver = :selenium
  session = Capybara::Session.new :selenium
  @homepage = HomePage.new(session)
  @homepage.goto_homepage(full_host)
  puts "Opening home page: " + full_host
  return @homepage
end