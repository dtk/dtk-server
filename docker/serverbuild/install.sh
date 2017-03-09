mkdir -p /etc/puppet/

#ln -sf dtk-provisioning/modules /etc/puppet/
#cp docker/manifests /tmp/manifests
ln -sf $(pwd)/docker/addons /

chown -R ${tenant_user}:${tenant_user} /home/${tenant_user}

apt-get update
puppet apply --debug --modulepath dtk-provisioning/modules docker/manifests/stage3.pp

apt-get clean && apt-get autoclean && apt-get -y autoremove

rm -rf /etc/puppet/modules /tmp/* /var/lib/postgresql/ /var/lib/apt/lists/* /var/tmp/* 