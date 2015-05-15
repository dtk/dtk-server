FROM getdtk/precise-puppet:0.5
MAINTAINER dduvnjak <dario@atlantbh.com>

RUN mkdir -p /etc/puppet
RUN mkdir -p /usr/share/dtk

COPY dtk_modules /etc/puppet/modules
COPY docker/tenant.pp /tenant.pp

ADD docker/apply.sh apply.sh

RUN /apply.sh

COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN echo "daemon off;" >> /etc/nginx/nginx.conf

ADD docker/init.sh init.sh
ADD docker/setup.sh setup.sh 

COPY docker/socket.conf /etc/nginx/conf.d/socket.conf

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD ["/setup.sh"]
