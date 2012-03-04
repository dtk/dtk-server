class hdp-hadoop::params(
) inherits hdp::params 
{
  
  $conf_dir = hdp_default("hadoop_conf_dir","/etc/hadoop")
  $namenode_formatted_mark_file = "${conf_dir}/namenode-formatted"

  ####### users

  $mapred_user = hdp_default("mapred_user","mapred")
  $hdfs_user = hdp_default("hdfs_user","hdfs")
  
  ### hadoop-env
  
  $dtnode_heapsize = hdp_default("hadoop/hadoop-env/dtnode_heapsize","1024m")

  $hadoop_heapsize = hdp_default("hadoop/hadoop-env/hadoop_heapsize","1024m")

  $hadoop_logdirprefix = hdp_default("hadoop/hadoop-env/hadoop_logdirprefix","/var/log/hadoop")

  $hadoop_piddirprefix = hdp_default("hadoop/hadoop-env/hadoop_piddirprefix","/var/run/hadoop")

  $jtnode_heapsize = hdp_default("hadoop/hadoop-env/jtnode_heapsize","1024m")

  $jtnode_opt_maxnewsize = hdp_default("hadoop/hadoop-env/jtnode_opt_maxnewsize","200m")

  $jtnode_opt_newsize = hdp_default("hadoop/hadoop-env/jtnode_opt_newsize","200m")

  $namenode_javaheap = hdp_default("hadoop/hadoop-env/namenode_javaheap","1024m")

  $namenode_opt_maxnewsize = hdp_default("hadoop/hadoop-env/namenode_opt_maxnewsize","640m")

  $namenode_opt_newsize = hdp_default("hadoop/hadoop-env/namenode_opt_newsize","640m")
  
  #TODO: probably move to hdp since shared accross components
  ### core-site
  $compression_codecs = hdp_default("hadoop/core-site/compression_codecs")

  $enable_security_authorization = hdp_default("hadoop/core-site/enable_security_authorization","false")

  $fs_inmemory_size = hdp_default("hadoop/core-site/fs_inmemory_size",256)

  $proxyuser_group = hdp_default("hadoop/core-site/proxyuser_group")

  $proxyuser_host = hdp_default("hadoop/core-site/proxyuser_host")

  $security_type = hdp_default("hadoop/core-site/security_type","simple")
  
  ### hdfs-site
  $datanode_du_reserved = hdp_default("hadoop/hdfs-site/datanode_du_reserved",1073741824)

  $dfs_block_local_path_access_user = hdp_default("hadoop/hdfs-site/dfs_block_local_path_access_user","hbase")

  #$dfs_data_dir = hdp_default("hadoop/hdfs-site/dfs_data_dir","/tmp/hadoop-hdfs/dfs/data")
  $dfs_data_dir = hdp_default("hadoop/hdfs-site/dfs_data_dir","/grid/0/hdp/hdfs/data,/grid/1/hdp/hdfs/data,/grid/2/hdp/hdfs/data,/grid/3/hdp/hdfs/data")

  $dfs_datanode_address = hdp_default("hadoop/hdfs-site/dfs_datanode_address",50010)

  $dfs_datanode_data_dir_perm = hdp_default("hadoop/hdfs-site/dfs_datanode_data_dir_perm",750)

  $dfs_datanode_failed_volume_tolerated = hdp_default("hadoop/hdfs-site/dfs_datanode_failed_volume_tolerated",0)

  $dfs_datanode_http_address = hdp_default("hadoop/hdfs-site/dfs_datanode_http_address",50075)

  $dfs_exclude = hdp_default("hadoop/hdfs-site/dfs_exclude","dfs.exclude")

  $dfs_include = hdp_default("hadoop/hdfs-site/dfs_include","dfs.include")
  
#  $dfs_name_dir = hdp_default("hadoop/hdfs-site/dfs_name_dir","/tmp/hadoop-hdfs/dfs/name")
  $dfs_name_dir = hdp_default("hadoop/hdfs-site/dfs_name_dir","/grid/0/hdp/hdfs/name")
  
  $dfs_replication = hdp_default("hadoop/hdfs-site/dfs_replication",1) #TODO: for testing
  
  $dfs_support_append = hdp_default("hadoop/hdfs-site/dfs_support_append",true)

  $dfs_webhdfs_enabled = hdp_default("hadoop/hdfs-site/dfs_webhdfs_enabled","false")


 ######### mapred #######
   ### mapred-site

  $mapred_system_dir = '/mapred/system'

  $io_sort_mb = hdp_default("hadoop/mapred-site/io_sort_mb","200m")

  $io_sort_spill_percent = hdp_default("hadoop/mapred-site/io_sort_spill_percent","0.9")

  $mapred_child_java_opts_sz = hdp_default("hadoop/mapred-site/mapred_child_java_opts_sz","-Xmx768m")

  $mapred_cluster_map_mem_mb = hdp_default("hadoop/mapred-site/mapred_cluster_map_mem_mb","-1")

  $mapred_cluster_max_map_mem_mb = hdp_default("hadoop/mapred-site/mapred_cluster_max_map_mem_mb","-1")

  $mapred_cluster_max_red_mem_mb = hdp_default("hadoop/mapred-site/mapred_cluster_max_red_mem_mb","-1")

  $mapred_cluster_red_mem_mb = hdp_default("hadoop/mapred-site/mapred_cluster_red_mem_mb","-1")

  $mapred_compress_map_output = hdp_default("hadoop/mapred-site/mapred_compress_map_output","false")

  $mapred_hosts_exclude = hdp_default("hadoop/mapred-site/mapred_hosts_exclude","/etc/hadoop/mapred.exclude")

  $mapred_hosts_include = hdp_default("hadoop/mapred-site/mapred_hosts_include","/etc/hadoop/mapred.include")

  $mapred_job_map_mem_mb = hdp_default("hadoop/mapred-site/mapred_job_map_mem_mb","-1")

  $mapred_job_red_mem_mb = hdp_default("hadoop/mapred-site/mapred_job_red_mem_mb","-1")

  $mapred_jobstatus_dir = hdp_default("hadoop/mapred-site/mapred_jobstatus_dir","file:////mapred/jobstatus")

  #$mapred_local_dir = hdp_default("hadoop/mapred-site/mapred_local_dir","/tmp/hadoop-mapred/mapred/local")
  $mapred_local_dir = hdp_default("hadoop/mapred-site/mapred_local_dir","/grid/0/hdp/mapred/local,/grid/1/hdp/mapred/local,/grid/2/hdp/mapred/local,/grid/3/hdp/mapred/local")
   
  $mapred_map_output_compression_codec = hdp_default("hadoop/mapred-site/mapred_map_output_compression_codec","org.apache.hadoop.io.compress.DefaultCodec")

  $mapred_map_tasks_max = hdp_default("hadoop/mapred-site/mapred_map_tasks_max",4)

  $mapred_red_tasks_max = hdp_default("hadoop/mapred-site/mapred_red_tasks_max",4)

  $mapreduce_userlog_retainhours = hdp_default("hadoop/mapred-site/mapreduce_userlog_retainhours",24)

  $maxtasks_per_job = hdp_default("hadoop/mapred-site/maxtasks_per_job","-1")

  $scheduler_name = hdp_default("hadoop/mapred-site/scheduler_name","org.apache.hadoop.mapred.CapacityTaskScheduler")

  $task_controller = hdp_default("hadoop/mapred-site/task_controller","org.apache.hadoop.mapred.DefaultTaskController")

  #### health_check

  $security_enabled = hdp_default("hadoop/health_check/security_enabled","false")

  $task_bin_exe = hdp_default("hadoop/health_check/task_bin_exe")
}
