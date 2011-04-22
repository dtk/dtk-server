#!/bin/sh
apt-get install ruby ruby-dev libopenssl-ruby rdoc ri irb build-essential wget ssl-cert
cd /tmp
wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz
tar zxf rubygems-1.3.7.tgz
cd rubygems-1.3.7
ruby setup.rb --no-format-executable &>> $log
gem install ohai chef --no-rdoc --no-ri
