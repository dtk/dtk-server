#!/bin/bash

echo "-------------------------------"
echo "Script for dtk server migration"
echo "-------------------------------"
echo ""

echo "Enter neccessary properties to perform migration:"

echo "Please specify old tenant host:"
read old_tenant_host
echo "Please specify new tenant user:"
read tenant_user
echo "Please specify new tenant git user:"
read git_user
echo "Please specify full path to the pem file needed for establishing connection with instance that hosts source dtk server:"
read pem_file_location

echo ""
echo "------------------------------------------------------------"
echo "Step 1: Copying resources needed for new dtk server instance"
echo "------------------------------------------------------------"
echo ""

copy_fog() {
        pem_file_location=$1
        remote_user=$2
        remote_host=$3
        dtk_server_user_name=$4

        sudo scp -r -i $pem_file_location $remote_user@$remote_host:"/home/"$dtk_server_user_name"/.fog" "/home/"$dtk_server_user_name
        if [[ $? == 0 ]]; then
            sudo chown $dtk_server_user_name:$dtk_server_user_name /home/$dtk_server_user_name/.fog
            echo "Copy of .fog file from remote host to new dtk server instance has been completed successfully!"
        else
            echo "[ERROR] Something went wrong! Copy of .fog file from remote host to new dtk server instance has not completed successfully!"
        fi
}

copy_gitolite_repositories() {
        pem_file_location=$1
        remote_user=$2
        remote_host=$3
        user_name=$4
        content_name=$5

        echo "Backup existing gitolite-admin.git repo..."
        sudo -u $user_name mkdir /home/$user_name/gitolite-admin-tmp
        sudo -u $user_name cp -r /home/$user_name/repositories/gitolite-admin.git /home/$user_name/gitolite-admin-tmp/

        echo "First, tar $content_name directory on remote host..."
        sudo ssh -i $pem_file_location $remote_user@$remote_host "cd /home/$user_name; sudo -u $user_name tar -zcf $content_name.tar.gz $content_name"
        if [[ $? == 0 ]]; then
                echo "Connecting to remote host and performing scp operation..."
                sudo scp -r -i $pem_file_location $remote_user@$remote_host:/home/$user_name/$content_name.tar.gz /home/$user_name
                if [[ $? == 0 ]]; then
                        sudo chown $user_name:$user_name /home/$user_name/$content_name.tar.gz
                        echo "Connecting to remote host and performing delete of tar content..."
                        sudo ssh -i $pem_file_location $remote_user@$remote_host "sudo -u $user_name rm -rf /home/$user_name/$content_name.tar.gz"
                        if [[ $? == 0 ]]; then
                                echo "Untar $content_name.tar.gz content on new dtk server instance..."
                                cd /home/$user_name
                                sudo tar -zxf $content_name.tar.gz
                                if [[ $? == 0 ]]; then
                                        echo "Remove $content_name.tar.gz content from new dtk server instance..."
                                        echo "Copy of $content_name from remote host to new dtk server instance has been completed successfully!"
                                        sudo rm -rf /home/$user_name/$content_name.tar.gz
                                        if [[ $? == 0 ]]; then
                                            echo "Removing tar content (from new dtk server instance) completed successfully!"
                                        else
                                            echo "[ERROR] Something went wrong! Tar content was not removed (from new dtk server instance) successfully!"
                                        fi
                                else
                                     echo "[ERROR] Something went wrong! Untar operation has not completed successfully!"
                                fi
                        else
                            echo "[ERROR] Something went wrong! Tar content was not removed (from remote host) successfully!"
                        fi
                else
                    echo "[ERROR] Something went wrong! Copy of $content_name (from remote host to new dtk server instance) has not completed successfully!"
                fi
        else
            echo "[ERROR] Something went wrong! Tar operation has not completed successfully!"
        fi

        echo "Restore old gitolite-admin.git repo..."
        sudo rm -rf /home/$user_name/repositories/gitolite-admin.git
        sudo -u $user_name cp -r /home/$user_name/gitolite-admin-tmp/gitolite-admin.git /home/$user_name/repositories/
        sudo -u $user_name chmod 775 /home/$user_name/repositories/gitolite-admin.git
        sudo rm -rf /home/$user_name/gitolite-admin-tmp

        echo "Execute gitolite setup command to enable write access control..."
        sudo su - $user_name -c "cd /home/$user_name;bin/gitolite setup"
        if [[ $? == 0 ]]; then
            echo "Gitolite setup command executed successfully!"
        else
            echo "[ERROR] Something went wrong! Gitolite setup command was not executed successfully!"
        fi
}

copy_gitolite_admin_conf_files() {
        pem_file_location=$1
        remote_user=$2
        remote_host=$3
        user_name=$4
        content_name=$5

        echo "First, tar $content_name directory on remote host..."
        sudo ssh -i $pem_file_location $remote_user@$remote_host "cd /home/$user_name/gitolite-admin/conf; sudo -u $user_name tar -zcf $content_name.tar.gz $content_name"
        if [[ $? == 0 ]]; then
                echo "Connecting to remote host and performing scp operation..."
                sudo scp -r -i $pem_file_location $remote_user@$remote_host:/home/$user_name/gitolite-admin/conf/$content_name.tar.gz /home/$user_name/gitolite-admin/conf
                if [[ $? == 0 ]]; then
                        sudo chown $user_name:$user_name /home/$user_name/gitolite-admin/conf/$content_name.tar.gz
                        echo "Connecting to remote host and performing delete of tar content..."
                        sudo ssh -i $pem_file_location $remote_user@$remote_host "sudo -u $user_name rm -rf /home/$user_name/gitolite-admin/conf/$content_name.tar.gz"
                        if [[ $? == 0 ]]; then
                                echo "Untar $content_name.tar.gz content on new dtk server instance..."
                                cd /home/$user_name/gitolite-admin/conf
                                sudo tar -zxf $content_name.tar.gz
                                if [[ $? == 0 ]]; then
                                        echo "Remove $content_name.tar.gz content from new dtk server instance..."
                                        echo "Copy of gitolite-admin conf files from remote host to new dtk server instance has been completed successfully!"
                                        sudo rm -rf /home/$user_name/gitolite-admin/conf/$content_name.tar.gz
                                        if [[ $? == 0 ]]; then
                                            echo "Removing tar content (from new dtk server instance) completed successfully!"
                                        else
                                            echo "[ERROR] Something went wrong! Tar content was not removed (from new dtk server instance) successfully!"
                                        fi
                                else
                                    echo "[ERROR] Something went wrong! Untar operation has not completed successfully!"
                                fi
                        else
                            echo "[ERROR] Something went wrong! Tar content was not removed (from remote host) successfully!"
                        fi
                else
                    echo "[ERROR] Something went wrong! Copy of gitolite-admin conf files (from remote host to new dtk server instance) has not completed successfully!"
                fi
        else
            echo "[ERROR] Something went wrong! Tar operation has not completed successfully!"
        fi

        echo "Add gitolite admin conf files in gitolite-admin clone repo and push changes"
        sudo su - $user_name -c "cd /home/$user_name/gitolite-admin;git add .;git commit -m \"update\";git push"      
}

copy_r8server-repo() {
        pem_file_location=$1
        remote_user=$2
        remote_host=$3
        user_name=$4
        content_name=$5
        git_user=$6

        echo "First, tar $content_name directory on remote host..."
        sudo ssh -i $pem_file_location $remote_user@$remote_host "cd /home/$user_name; sudo -u $user_name tar -zcf $content_name.tar.gz $content_name"
        if [[ $? == 0 ]]; then
                echo "Connecting to remote host and performing scp operation..."
                sudo scp -r -i $pem_file_location $remote_user@$remote_host:/home/$user_name/$content_name.tar.gz /home/$user_name
                if [[ $? == 0 ]]; then
                        sudo chown $user_name:$user_name /home/$user_name/$content_name.tar.gz
                        echo "Connecting to remote host and performing delete of tar content..."
                        sudo ssh -i $pem_file_location $remote_user@$remote_host "sudo -u $user_name rm -rf /home/$user_name/$content_name.tar.gz"
                        if [[ $? == 0 ]]; then
                                echo "Untar $content_name.tar.gz content on new dtk server instance..."
                                cd /home/$user_name
                                sudo tar -zxf $content_name.tar.gz
                                if [[ $? == 0 ]]; then
                                        echo "Remove $content_name.tar.gz content from new dtk server instance..."
                                        echo "Copy of $content_name from remote host to new dtk server instance has been completed successfully!"
                                        sudo rm -rf /home/$user_name/$content_name.tar.gz
                                        if [[ $? == 0 ]]; then
                                            echo "Removing tar content (from new dtk server instance) completed successfully!"
                                        else
                                            echo "[ERROR] Something went wrong! Tar content was not removed (from new dtk server instance) successfully!"
                                        fi
                                else
                                    echo "[ERROR] Something went wrong! Untar operation has not completed successfully!"
                                fi
                        else
                            echo "[ERROR] Something went wrong! Tar content was not removed (from remote host) successfully!"
                        fi
                else
                    echo "[ERROR] Something went wrong! Copy of $content_name (from remote host to new dtk server instance) has not completed successfully!"
                fi
        else
            echo "[ERROR] Something went wrong! Tar operation has not completed successfully!"
        fi

        echo "Setting remote origin for all cloned gitolite repos..."
        for f in `ls /home/$user_name/r8server-repo`; do
            echo "Setting git remote origin for $f..."
            /usr/bin/git --git-dir=/home/$user_name/r8server-repo/$f/.git remote set-url origin $git_user@localhost:$f
        done
}

ls $pem_file_location
if [[ $? == 0 ]]; then
        echo "pem file location is correct"

                echo ""
                echo "-----------------"
                echo "Copy of .fog file"
                echo "-----------------"
                echo ""
                copy_fog $pem_file_location "ubuntu" $old_tenant_host $tenant_user
                echo ""

                echo ""
                echo "-----------------------------------"
                echo "Copy of gitolite local repositories"
                echo "-----------------------------------"
                echo ""
                copy_gitolite_repositories $pem_file_location "ubuntu" $old_tenant_host $git_user "repositories"
                echo ""

                echo ""
                echo "---------------------------------"
                echo "Copy of gitolite-admin conf files"
                echo "---------------------------------"
                echo ""
                copy_gitolite_admin_conf_files $pem_file_location "ubuntu" $old_tenant_host $tenant_user "repo-configs"
                echo ""

                echo ""
                echo "---------------------------------------------------------------"
                echo "Copy of r8server-repo - cloned repositories from local gitolite"
                echo "---------------------------------------------------------------"
                echo ""
                copy_r8server-repo $pem_file_location "ubuntu" $old_tenant_host $tenant_user "r8server-repo" $git_user
                echo ""
else
        echo "[ERROR] Incorrect location of pem file! Script will EXIT now."
fi

echo ""
echo "-----------------------------"
echo "Step 2: Migrate dtk server db"
echo "-----------------------------"
echo ""

migrate_db() {
        pem_file_location=$1
        remote_user=$2
        remote_host=$3
        dtk_server_user_name=$4
        db_name=$5

        echo "First, stop existing tenant to execute db migration..."
        sudo thin -C /etc/thin/server.yaml stop

        echo "Database to be migrated is: $db_name"
        echo "First backup $db_name database on source dtk server..."
        sudo ssh -i $pem_file_location $remote_user@$remote_host "cd /home/$remote_user; sudo -u postgres pg_dump $db_name > $db_name.dump.out"
        if [[ $? == 0 ]]; then
                echo "Connecting to remote host and performing scp operation..."
                sudo scp -r -i $pem_file_location $remote_user@$remote_host:"/home/$remote_user/$db_name.dump.out" "/home/$dtk_server_user_name"
                if [[ $? == 0 ]]; then
                        sudo chown $dtk_server_user_name:$dtk_server_user_name "/home/$dtk_server_user_name/$db_name.dump.out"
                        echo "Connecting to remote host and performing delete of dump content..."
                        sudo ssh -i $pem_file_location $remote_user@$remote_host "sudo -u $remote_user rm -rf /home/$remote_user/$db_name.dump.out"
                        if [[ $? == 0 ]]; then
                                echo "Delete existing db on new dtk server instance..."
                                sudo -u postgres dropdb $db_name
                                echo "Create $db_name db on new dtk server instance..."
                                sudo -u postgres createdb $db_name --encoding=SQL_ASCII --template=template0
                                if [[ $? == 0 ]]; then
                                        echo "Restore $db_name db on new dtk server instance..."
                                        sudo -u postgres psql -d $db_name -f "/home/$dtk_server_user_name/$db_name.dump.out"
                                        if [[ $? == 0 ]]; then
                                                echo "Restore of $db_name db (on new dtk server instance) completed successfully!"
                                                sudo rm -rf "/home/$dtk_server_user_name/$db_name.dump.out"
                                                if [[ $? == 0 ]]; then
                                                    echo "Removing dump content (from new dtk server instance) completed successfully!"
                                                    echo "DB migration completed successfully!"
                                                else
                                                    echo "[ERROR] Something went wrong! Dump content $db_name.dump.out was not removed (from new dtk server instance) successfully!"
                                                fi
                                        else
                                            echo "[ERROR] Something went wrong! Restore of $db_name db (on new dtk server instance) was not completed successfully!"
                                        fi
                                else
                                    echo "[ERROR] Something went wrong! Create $db_name db has not completed successfully!"
                                fi
                        else
                            echo "[ERROR] Something went wrong! Dump content $db_name.dump.out was not removed (from remote host) successfully!"
                        fi
                else
                    echo "[ERROR] Something went wrong! Copy of dump content $db_name.dump.out (from remote host to new dtk server instance) has not completed successfully!"
                fi
        else
            echo "[ERROR] Something went wrong! Backup of $db_name database has not completed successfully!"
        fi

        echo "Start tenant after db migration..."
        sudo thin -C /etc/thin/server.yaml start
        if [[ $? == 0 ]]; then
            echo "Tenant has been started successfully!"
        else
            echo "[ERROR] Something went wrong! Tenant has not been started successfully!"
        fi
}

migrate_db $pem_file_location "ubuntu" $old_tenant_host $tenant_user $tenant_user
