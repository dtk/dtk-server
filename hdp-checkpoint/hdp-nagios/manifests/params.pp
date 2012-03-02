class hdp-nagios::params() inherits hdp::params
{   
 
 
  $conf_dir = hdp_default("nagios_conf_dir","/etc/nagios")
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
