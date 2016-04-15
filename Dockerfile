FROM getdtk/baseimage:0.10
MAINTAINER dduvnjak <dario@atlantbh.com>

RUN mkdir -p /etc/puppet/modules

COPY dtk-provisioning/modules /etc/puppet/modules
COPY docker/manifests /tmp/manifests
COPY docker/addons /addons

ENV tenant_user=dtk1
RUN useradd -ms /bin/bash ${tenant_user}
RUN mkdir -p /home/${tenant_user}/server
RUN mkdir -p /home/${tenant_user}/.ssh
COPY . /home/${tenant_user}/server/current
RUN chown -R ${tenant_user}:${tenant_user} /home/${tenant_user}

RUN apt-get update
RUN puppet apply --debug /tmp/manifests/stage3.pp

RUN apt-get clean && apt-get autoclean && apt-get -y autoremove

RUN rm -rf /etc/puppet/modules /tmp/* /var/lib/postgresql/ /var/lib/apt/lists/* /var/tmp/*

EXPOSE 2222
EXPOSE 6163
EXPOSE 80

CMD ["/addons/init.sh"]
