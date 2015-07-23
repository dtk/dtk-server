FROM getdtk/baseimage:0.1
MAINTAINER dduvnjak <dario@atlantbh.com>

ENV tenant_user=dtk1

RUN mkdir -p /etc/puppet/modules

COPY dtk_modules /etc/puppet/modules

COPY docker/manifests /tmp/manifests

COPY docker/addons /addons

RUN useradd -ms /bin/bash ${tenant_user}

RUN mkdir -p /home/${tenant_user}/server

RUN mkdir -p /home/${tenant_user}/.ssh

COPY . /home/${tenant_user}/server/current

RUN chown -R ${tenant_user}:${tenant_user} /home/${tenant_user}

RUN puppet apply --debug /tmp/manifests/stage3.pp

RUN apt-get clean

RUN rm -rf /etc/puppet/modules /tmp/* /var/lib/postgresql/ /var/lib/apt/lists/* /var/tmp/*

EXPOSE 2222
EXPOSE 6163
EXPOSE 80

CMD ["/addons/init.sh"]
