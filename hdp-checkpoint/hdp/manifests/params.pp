class hdp::params()
{
  ### hostnames
  $namenode_host = hdp_default("namenode_host")
  $jtnode_host = hdp_default("jtnode_host")
  $snamenode_host = hdp_default("namenode_host")
  $zookeeper_hosts = hdp_default("zookeeper_hosts")
  $hbase_master_host = hdp_default("hbase_master_host")

  
  #TODO: either remove or make conditional on ec2
  #TODO: may want to use private address to sync with rDNS
  #for self
  $host_address = $::ec2_public_hostname #TODO: works with facter 1.6.4, but not facter 1.6.5
  #$host_address = $::fqdn

  #####

  #TODO: need to allow multiple paths if 32 + 64
  $java_home = hdp_default("java_home","/usr/java/default")
  $hadoop_home = hdp_default("hadoop_home","/usr")

  $hadoop_user = hdp_default("hadoop_user", "hadoop")
  $hadoop_user_group = hdp_default("hadoop_user_group","hadoop")

  $exec_path = ["/bin","/usr/bin", "/usr/sbin"]
 
  $repo_url = hdp_default("repo_url","http://public-repo-1.hortonworks.com/HDP-1.0.1-PREVIEW-2")
  $package_file_names = hdp_default("package_file_names",{
    hadoop => {
      32 => 'hadoop-1.0.0-1.i386.rpm', 
      64 => 'hadoop-1.0.0-1.amd64.rpm' 
    },
    zookeeper => {
      64 => 'zookeeper-3.3.4-1.x86_64.rpm'
    },
    hbase => {
      64 => 'hbase-0.92.0-1.x86_64.rpm'
    },
    hcat-server => {
      64 => 'hcatalog-server-0.3.0-1.amd64.rpm'
    },
    hcat-base => {
      64 => 'hcatalog-0.3.0-1.amd64.rpm'
    }
  })
  $artifact_dir = hdp_default("artifact_dir","/tmp/HDP-artifacts/") #bashvar: artifactdownloaddir
  

 ####kerberos
   #$kerberos_domain = hdp_default("hadoop/hdfs-site/kerberos_domain","EXAMPLE.COM")
   #$kerberos_domain = hdp_default("hadoop/mapred-site/kerberos_domain","EXAMPLE.COM")
   ##$kerberos_domain = hdp_default("hadoop/core-site/kerberos_domain")
   ##$kerberos_domain = hdp_default("hadoop/mapred-site/kerberos_domain")
   ## $kerberos_domain = hdp_default("hadoop/hbase-site/kerberos_domain")

   ##$keytab_path = hdp_default("hadoop/hdfs-site/keytab_path")
   ##$keytab_path = hdp_default("hadoop/mapred-site/keytab_path")
   ##$keytab_path = hdp_default("hadoop/mapred-site/keytab_path")
   ##$keytab_path = hdp_default("hadoop/hbase-site/keytab_path")

}
