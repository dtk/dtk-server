maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs and configures haproxy"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version           "0.8.2"

recipe "haproxy", "Installs and configures haproxy load balancing"

%w{ debian ubuntu }.each do |os|
  supports os
end

require File.expand_path('metadata_aux.rb',::Chef::Config[:cucumber_path]);__t(__FILE__,self)
