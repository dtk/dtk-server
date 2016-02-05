#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
 ./utility/clear_db.sh ; ./utility/dbrebuild.rb ; ./utility/initialize.rb --delete; ./utility/add_user.rb joe
 ./utility/add_user.rb joe --create-private stdlib,hdp,hdp-hadoop,hdp-zookeeper,hdp-hbase,hdp-nagios,hdp-ganglia,hdp-dashboard,hdp-monitor-webserver
 ./utility/add_user.rb joe --create-private mysql,hdp-mysql,hdp-hcat,hdp-hive,hdp-pig,hdp-sqoop
 ./utility/add_user.rb joe --create-private kerberos,hdp-java-jce
 ./utility/add_user.rb joe --create-private gitolite,dtk_repo_manager,thin
