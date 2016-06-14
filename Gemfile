source 'https://rubygems.org'

# dtk gems
#TODO: commented until we solve issue with nee to get latest versions from our geminabox not rubygems
gem 'dtk-common', :github => 'dtk/dtk-common'
gem 'dtk-common-core', :github => 'dtk/dtk-common-core', :branch => 'DTK-2589'

# required to start a server
gem 'bundler', '>= 1.1.5'
gem 'fog'
gem 'ramaze', '2012.04.14'
gem 'sequel', '3.25.0'
gem 'activesupport'
gem 'i18n'
gem 'ruote', '2.3.0.1'
gem 'eventmachine', '1.0.8'
gem 'pg', '0.14.1'
gem 'json'
gem 'rspec', '2.99.0'
gem 'sshkey', '1.6.1'
gem 'sshkeyauth', '0.0.11'
gem 'iconv'
gem 'thin'
gem 'addressable'
gem 'colorize', '~> 0.5.8'
# gem 'rack-contrib'
gem 'awesome_print', '1.1.0'
gem 'celluloid'
gem 'excon'
gem 'mime'

#TODO: moved back to 0.17.0.b7; looks like running into bug with 0.19.0 (7/27/13)
gem 'rugged', '0.17.0.b7'

#case RUBY_VERSION
#  when '1.8.7' then gem 'rugged','0.17.0.b7'
#  when '1.9.3' then gem 'rugged','0.19.0'
#end

group :development do
case RUBY_VERSION
  when /1.8.7.*/ then
    gem 'ruby-debug', '0.10.4'
  else
    gem 'debugger'
    gem 'em-ssh', '0.6.5'
end
end

# required to successfully run it
# Minor change

# Version That will work, bumped it so we could
# bump fog as well.
# gem 'chef','~>0.10.2' BuMP CHEF!!!!
gem 'chef', '11.18.12'
gem 'mcollective-client', '2.2.3'
#gem 'puppet','2.7.6'
gem 'puppet', '3.4.0'
gem 'stomp', '1.1.9'
gem 'grit', '2.5.0'
gem 'innate', '2012.03' #version compatible with ramaze','2012.04.14
gem 'ruby_parser'
gem 'docile'
gem 'redis'

gem 'looksee'
gem 'mustache', '~> 0.99.8'
