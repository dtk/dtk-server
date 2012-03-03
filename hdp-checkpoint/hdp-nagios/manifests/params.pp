class hdp-nagios::params() inherits hdp::params
{   
 
 
  $nagios_user = "nagios"
  $nagios_group = "nagios"
  
  $conf_dir = hdp_default("nagios_conf_dir","/etc/nagios")
  #TODO: note if $nagios_obj_dir different than "/etc/nagios/", Puppet nagios resources only provide partial support
  $nagios_obj_dir = hdp_default("nagios_obj_dir","/etc/nagios/objects")
  
  $nagios_host_cfg = hdp_default("nagios_host_cfg","${nagios_obj_dir}/nagios-hadoop-hosts.cfg")
  $nagios_hostgroup_cfg = hdp_default("nagios_hostgroup_cfg","${nagios_obj_dir}/nagios-hadoop-hostgroups.cfg")
  $nagios_service_cfg = hdp_default("nagios_service_cfg","${nagios_obj_dir}/nagios-hadoop-services.cfg")
  $nagios_command_cfg = hdp_default("nagios_command_cfg","${nagios_obj_dir}/nagios-hadoop-commands.cfg")
  
  
  $nagios_web_login = hdp_default("nagios_web_login","nagiosadmin")
  $nagios_web_password = hdp_default("nagios_web_password","admin")
  
  $datanode_dir =  hdp_default("nagios/nagios-hadoop-services/datanode_dir") #TODO: must be same as what is set/used in hadoop
   
  $nagios_contact = hdp_default("nagios/nagios-contacts/nagios_contact","monitor\@monitor.com")
 
  $nagios_download_info = hdp_default("nagios_download_info",{
      server => {
        url => "http://pkgs.repoforge.org/nagios/nagios-3.2.3-3.el5.rf.x86_64.rpm",
        rpm => "nagiosserver.rpm",
        options => "--nogpgcheck",
        creates => "/usr/bin/nagios",
        provider => "yum"
      },
      plugins => {
        url => "http://pkgs.repoforge.org/nagios-plugins/nagios-plugins-1.4.9-1.el5.rf.x86_64.rpm",
        rpm => "nagiosplugins.rpm",
        options => "--nodeps",
        creates => "/usr/lib64/nagios/plugins/check_ssh",
        provider => "rpm"
      },
       fping => {
        url => "http://pkgs.repoforge.org/fping/fping-2.4-1.b2.3.el5.rf.x86_64.rpm",
        rpm => "fping-rf.rpm",
        options => "--nogpgcheck",
        creates => "/usr/lib64/nagios/plugins/check_fping",
        provider => "yum"
      },
      perl_net_snmp => {
        url => "http://pkgs.repoforge.org/perl-Net-SNMP/perl-Net-SNMP-5.2.0-1.2.el5.rf.noarch.rpm",
        rpm => "perlNetSNMP-rf.rpm",
        options => "--nogpgcheck",
        creates => "", #TODO: detrmine what it creates
        provider => "yum"
      }
  })
}
