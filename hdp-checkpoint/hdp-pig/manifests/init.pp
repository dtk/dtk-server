class hdp-pig()
{   
  include hdp-pig::params
  hdp::package { 'pig' : }

  hdp-pig::configfile { 'pig-env.sh': }
  hdp-pig::configfile { 'pig.properties': }
  hdp-pig::configfile { 'log4j.properties': }
  
  anchor { 'hdp-pig::begin': } -> Hdp::Package['pig'] -> anchor { 'hdp-pig::end': }
}

### config files
define hdp-pig::configfile()
{
}

define hdp-pig::save-configfile()
{
  hdp::configfile { $name:
    component        => 'pig',
    conf_dir         => $hdp-pig::params::pig_conf_dir
  }
}



