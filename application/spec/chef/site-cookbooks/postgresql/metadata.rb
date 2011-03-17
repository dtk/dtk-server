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
recipe            "postgresql::pgpool", "Installs pgpool load balancer"
recipe            "postgresql::app", "Test app"
recipe            "postgresql::db", "Postgresql DB"


%w{rhel centos fedora ubuntu debian suse}.each do |os|
  supports os
end

attribute "postgresql/db_component",
  :default => "postgresql__db",
  :recipes => ["postgresql::server"]

attribute "postgresql/max_connections",
  :default => "100",
  :recipes => ["postgresql::server"]

attribute "postgresql/shared_buffers",
  :default => "28MB",
  :recipes => ["postgresql::server"]


attribute "postgresql/effective_cache_size",
  :default => "128MB",
  :recipes => ["postgresql::server"]


require File.expand_path('metadata_aux.rb',::Chef::Config[:cucumber_path]);__t(__FILE__,self)
