source 'http://rubygems.org'
source 'http://dtkuser:g3msdtk@gems.r8network.com/'

# dtk gems
#TODO commented until we solve issue with nee to get latest versions from our geminabox not rubygems
gem 'dtk-common', :git => 'git@github.com:rich-reactor8/dtk-common.git' #, :tag => '>= 0.5.15'
gem 'dtk-common-core', :git => 'git@github.com:rich-reactor8/dtk-common-repo.git'

# required to start a server
gem 'bundler','>= 1.1.5'
gem 'fog','1.8.0'
gem 'ramaze','2012.04.14'
gem 'sequel','3.25.0'
gem 'activesupport','~> 3.0.0'
gem 'ruote','2.3.0.1'
gem 'eventmachine','1.0.0'
gem 'pg','0.14.1'
gem 'json','1.5.2'
gem 'rspec','2.11.0'
gem 'sshkey','1.6.1'
gem 'sshkeyauth', '0.0.11'
gem 'thin'
gem 'iconv'
gem 'colorize','~> 0.5.8'
# gem 'rack-contrib'
gem 'awesome_print','1.1.0'
case RUBY_VERSION
 when  /1.9.3.*/ then  gem 'em-ssh', '0.6.5'
end
#TODO: can upgrade this after fix [#<NoMethodError: undefined method `attributes' for #<Excon::Response:0x0000000529aec8>>, ["/home/dtk18/server/utils/internal/cloud_connect.rb:27:in `hash_form'"
gem 'excon', '0.16.10'

#TODO: moved back to 0.17.0.b7; looks like running into bug with 0.19.0 (7/27/13)
gem 'rugged','0.17.0.b7'

#case RUBY_VERSION
#  when '1.8.7' then gem 'rugged','0.17.0.b7'
#  when '1.9.3' then gem 'rugged','0.19.0'
#end

case RUBY_VERSION
  when /1.8.7.*/ then gem 'ruby-debug','0.10.4'
  when /1.9.3.*/ then gem 'debugger'
end


# required to successfully run it
# Minor change

# Version That will work, bumped it so we could
# bump fog as well.
# gem 'chef','~>0.10.2' BuMP CHEF!!!!
gem 'chef','10.16.2'
gem 'mcollective-client','2.2.3'
#gem 'puppet','2.7.6'
gem 'puppet','3.1.0'
gem 'stomp','1.1.9'
gem 'grit','2.5.0'
gem 'innate','2012.03' #version compatible with ramaze','2012.04.14
gem 'ruby_parser', '2.3.1' #found bug with ruote listen expression unless degrade to this version
gem 'docile'

gem 'looksee'


