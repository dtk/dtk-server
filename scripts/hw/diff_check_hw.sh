cd /root/r8server-repo/joe-puppet-hdp
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-hadoop
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-zookeeper
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-hbase
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-hcat
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-hive
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-pig
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-oozie
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-sqoop
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-nagios
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-ganglia
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-dashboard
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-monitor-webserver
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-mysql
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-mysql
git checkout project-private-joe-v1

cd /root/r8server-repo
diff -r joe-puppet-hdp ~/HMC/src/puppet/modules/hdp
diff -r joe-puppet-hdp-hadoop/ ~/HMC/src/puppet/modules/hdp-hadoop/
diff -r joe-puppet-hdp-zookeeper/ ~/HMC/src/puppet/modules/hdp-zookeeper/
diff -r joe-puppet-hdp-hbase/ ~/HMC/src/puppet/modules/hdp-hbase/
diff -r joe-puppet-hdp-hcat/ ~/HMC/src/puppet/modules/hdp-hcat/
diff -r joe-puppet-hdp-hive/ ~/HMC/src/puppet/modules/hdp-hive/
diff -r joe-puppet-hdp-pig/ ~/HMC/src/puppet/modules/hdp-pig/
diff -r joe-puppet-hdp-oozie/ ~/HMC/src/puppet/modules/hdp-oozie/
diff -r joe-puppet-hdp-sqoop/ ~/HMC/src/puppet/modules/hdp-sqoop/
diff -r joe-puppet-hdp-nagios/ ~/HMC/src/puppet/modules/hdp-nagios
diff -r joe-puppet-hdp-ganglia/ ~/HMC/src/puppet/modules/hdp-ganglia
diff -r joe-puppet-hdp-dashboard/ ~/HMC/src/puppet/modules/hdp-dashboard
diff -r joe-puppet-hdp-monitor-webserver/ ~/HMC/src/puppet/modules/hdp-monitor-webserver
diff -r joe-puppet-hdp-mysql/ ~/HMC/src/puppet/modules/hdp-mysql
diff -r joe-puppet-mysql/ ~/HMC/src/puppet/modules/mysql



