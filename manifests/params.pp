class dtk_passenger::params()
 {
   $rvm_path  = "/usr/local/rvm"
   $ruby_path = "${rvm_path}/wrappers/default/ruby"

   case $::osfamily {
       'Debian' : {
          $package_list = ["nginx-full", "passenger"]
        }
       'RedHat', 'Linux' : {
          $package_list = ["nginx-passenger"]
       }
       default: {
          fail("\"${module_name}\" provides no package information for OSfamily \"${::osfamily}\"")
      } 
    }
  }