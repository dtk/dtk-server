class hdp::params()
{
  ### hostnames
  $namenode_host = hdp_default("namenode_host")
  $jtnode_host = hdp_default("jtnode_host")
  $snamenode_host = hdp_default("snamenode_host")
  $zookeeper_hosts = hdp_default("zookeeper_hosts")
  $hbase_master_host = hdp_default("hbase_master_host")
  $hcat_server_host = hdp_default("hcat_server_host")
  $hcat_mysql_host = hdp_default("hcat_mysql_host")
  
  #TODO: either remove or make conditional on ec2
  #TODO: may want to use private address to sync with rDNS
  #for self
  #TODO: may be safe to keep in becasue if not ec2 will be undefined; alternatively set to $host_address = undef
  $host_address = $::ec2_public_hostname #TODO: works with facter 1.6.4, but not facter 1.6.5
  #$host_address = $::fqdn

  ##### java 
  #TODO: should we check what is in java32/64 to see if should install java or have explicit flag?
  #btter normaize inputs for java
  $java32_home = hdp_default("java32_home","/usr/jdk32/jdk1.6.0_26")
  $java64_home = hdp_default("java64_home","/usr/java/default") #TODO: change to  "/usr/jdk64/jdk1.6.0_26"
  $java_home = hdp_default("java_home","/usr/java/default") #TODO: deprecate once incorporate above
  
  $jdk_location = hdp_default("jdk_location","http://download.oracle.com/otn-pub/java/jdk/6u26-b03")
  $jdk_bins = hdp_default("jdk_bins",{
    32 => "jdk-6u26-linux-i586.bin",
    64 => "jdk-6u26-linux-x64.bin"
  })
  
  #####

  $hadoop_home = hdp_default("hadoop_home","/usr")

  $hadoop_user = hdp_default("hadoop_user", "hadoop")
  $hadoop_user_group = hdp_default("hadoop_user_group","hadoop")

  $exec_path = ["/bin","/usr/bin", "/usr/sbin"]
  
  ##### packages/repos
 
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
    },
    pig => {
      32 => 'pig-0.9.2-1.i386.rpm'
    }
  })
  $artifact_dir = hdp_default("artifact_dir","/tmp/HDP-artifacts/") 
  
  #### TODO: yum base; wil replace above
  $yum_repo = hdp_default("hdp_yum_repo", "http://linuxrepo.s3-website-us-west-1.amazonaws.com/yumrepo/HDP-1.0.1-PREVIEW-3/hdp.repo")
  
  $package_names = hdp_default("package_names",{
    hadoop => {
      32 => 'hadoop.i386', 
      64 => 'hadoop.x86_64' 
    },
    zookeeper => {
      64 => 'zookeeper.x86_64'
    },
    hbase => {
      64 => 'hbase.x86_64'
    },
    hcat-server => {
    #  64 => ''
    },
    hcat-base => {
     # 64 => ''
    },
    pig => {
      32 => 'pig.i386'
    }
  })
 # $artifact_dir = hdp_default("artifact_dir","/tmp") 

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
