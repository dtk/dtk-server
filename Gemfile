source 'https://rubygems.org'

# dtk gems
gem 'dtk-common', :github => 'dtk/dtk-common'
gem 'dtk-common-core', :github => 'dtk/dtk-common-core'
gem 'dtk-dsl', :github => 'dtk/dtk-dsl'

# required to start a server
gem 'ramaze', '2012.04.14'
gem 'sequel', '3.25.0'
gem 'activesupport'
gem 'i18n'
gem 'ruote', '2.3.0.1'
gem 'eventmachine', '1.0.8'
gem 'pg', '0.14.1'
gem 'json', '1.8.3'
gem 'rspec', '2.99.0'
gem 'sshkey', '1.6.1'
gem 'sshkeyauth', '0.0.11'
gem 'iconv'
gem 'thin'
gem 'addressable'
gem 'colorize', '~> 0.5.8'
gem 'awesome_print', '1.1.0'
gem 'celluloid'
gem 'excon'
gem 'mime'

# TODO: might make this conditional whether providing a route for sts
gem 'aws-sdk'

#TODO: moved back to 0.17.0.b7; looks like running into bug with 0.19.0 (7/27/13)
gem 'rugged', '0.17.0.b7'

group :development do
case RUBY_VERSION
  when /1.8.7.*/ then
    gem 'ruby-debug', '0.10.4'
  else
    gem 'debugger'
    gem 'em-ssh', '0.6.5'
  end
end

gem 'mcollective-client', '~> 2.5.2'
gem 'puppet', '3.4.0'
gem 'stomp', '1.1.9'
gem 'grit'
gem 'innate', '2012.03' #version compatible with ramaze','2012.04.14


gem 'ruby_parser'
gem 'docile'
gem 'redis'

gem 'looksee'
gem 'mustache', '~> 0.99.8'

gem 'net-scp'
