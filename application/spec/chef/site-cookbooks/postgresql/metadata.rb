maintainer        "Reactor8"
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs and configures postgresql for clients or servers"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version           "0.11.1"
recipe            "postgresql", "Empty, use one of the other recipes"
recipe            "postgresql::client", "Installs postgresql client package(s)"
recipe            "postgresql::server", "Installs postgresql server packages, templates"
recipe            "postgresql::redhat", "Installs postgresql server packages, redhat family style"
recipe            "postgresql::server", "Installs postgresql server packages, debian family style"
recipe            "postgresql::app", "Test app"

%w{rhel centos fedora ubuntu debian suse}.each do |os|
  supports os
end

require File.expand_path('metadata_aux.rb',::Chef::Config[:cucumber_path]);__t(__FILE__,self)
