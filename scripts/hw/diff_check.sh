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
cd /root/r8server-repo/joe-puppet-hdp-pig
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-nagios
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-ganglia
git checkout project-private-joe-v1
cd /root/r8server-repo/joe-puppet-hdp-dashboard
git checkout project-private-joe-v1

cd /root/r8server-repo
diff -r joe-puppet-hdp /root/R8Server/hdp-checkpoint/hdp
diff -r joe-puppet-hdp-hadoop/ /root/R8Server/hdp-checkpoint/hdp-hadoop/
diff -r joe-puppet-hdp-zookeeper/ /root/R8Server/hdp-checkpoint/hdp-zookeeper/
diff -r joe-puppet-hdp-hbase/ /root/R8Server/hdp-checkpoint/hdp-hbase/
diff -r joe-puppet-hdp-hcat/ /root/R8Server/hdp-checkpoint/hdp-hcat/
diff -r joe-puppet-hdp-pig/ /root/R8Server/hdp-checkpoint/hdp-pig/
diff -r joe-puppet-hdp-nagios/ /root/R8Server/hdp-checkpoint/hdp-nagios/
diff -r joe-puppet-hdp-ganglia/ /root/R8Server/hdp-checkpoint/hdp-ganglia/
diff -r joe-puppet-hdp-dashboard/ /root/R8Server/hdp-checkpoint/hdp-dashboard/


