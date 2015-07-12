# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, 'DTK'
set :repo_url, 'git@github.com:rich-reactor8/server.git'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '~/server'

# set :tmp_dir, "/tmp"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

## Override the default git wrapper task
namespace :git do
  desc 'Upload the git wrapper script, this script guarantees that we can script git without getting an interactive prompt'
  task :wrapper do
    Rake::Task['git:wrapper'].clear
    on release_roles(:all), in: :sequence do
      execute :mkdir, '-p', "#{fetch(:tmp_dir)}/#{fetch(:application)}/"
      execute :sudo, 'chmod -R 777', "#{fetch(:tmp_dir)}/#{fetch(:application)}"
      upload! StringIO.new("#!/bin/sh -e\nexec /usr/bin/ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no \"$@\"\n"), "#{fetch(:tmp_dir)}/#{fetch(:application)}/git-ssh.sh"
    end
  end
end

namespace :deploy do
  desc 'Restart thin'
  task :restart do
    on roles(:app), in: :groups do |role|
      # Restart the thin service:
      sudo "/etc/init.d/thin-#{role.user} stop"
      sudo "/etc/init.d/thin-#{role.user} start"
    end
  end

  desc 'Start thin'
  task :start do
    on roles(:app), in: :groups do |role|
      # Start the thin service:
      sudo "/etc/init.d/thin-#{role.user} start"
    end
  end

  desc 'Stop thin'
  task :stop do
    on roles(:app), in: :groups do |role|
      # Stop the thin service:
      sudo "/etc/init.d/thin-#{role.user} stop"
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  desc 'Run initialize.rb'
  task :initialize do
    on roles(:app), in: :groups, limit: 3 do
      execute "cd #{release_path}/application; ./utility/initialize.rb"
    end
  end

  desc 'Run database migrations'
  task :migration do
    on roles(:app, :db), in: :groups, limit: 3 do
      execute "cd #{release_path}/application; ./utility/dbrebuild.rb"
    end
  end
end
