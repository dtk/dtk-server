maintainer       "Runa Inc."
maintainer       "Rich Pelavin"
maintainer_email "ops@runa.com"
license          "Apache 2.0"
description      "Installs/Configures redis"
recipe            "redis", "Installs/Configures redis"
version           "0.0.1"
###TODO may put in seprate file
attribute "_meta_info",
  :basic_types => {
    "redis" => "service" 
   }

require File.expand_path('metadata_aux.rb',::Chef::Config[:cucumber_path]);__t(__FILE__,self)

