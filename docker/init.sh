#!/usr/bin/env bash

. /dtk-creds/creds
cd /home/dtk1/server/current
/usr/local/rvm/wrappers/default/bundle exec /home/dtk1/server/current/application/utility/dbrebuild.rb
/usr/local/rvm/wrappers/default/bundle exec /home/dtk1/server/current/application/utility/initialize.rb
/usr/local/rvm/wrappers/default/bundle exec /home/dtk1/server/current/application/utility/add_user.rb ${DTK_USER} -p ${DTK_PASSWORD}
