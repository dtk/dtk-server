 ./spec/clear_db.sh ; ./spec/dbrebuild.rb ; ./spec/import/initialize.rb --delete
 ./spec/import/add_user.rb joe --create-private stdlib,hdp,hdp-hadoop,hdp-zookeeper,hdp-hbase,hdp-nagios,hdp-ganglia,hdp-dashboard,hdp-monitor-webserver
 ./spec/import/add_user.rb joe --create-private mysql,hdp-mysql,hdp-hcat,hdp-hive,hdp-pig,hdp-sqoop
 ./spec/import/add_user.rb joe --create-private kerberos,hdp-java-jce
 ./spec/import/add_user.rb joe --create-private gitolite,dtk_repo_manager,thin










