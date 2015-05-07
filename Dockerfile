FROM dduvnjak/precise-puppet:0.5
MAINTAINER dduvnjak <dario@atlantbh.com>

#RUN apt-get update
#RUN apt-get install sudo curl supervisor postgresql-client -y

#ENV RUBY_VERSION 1.9.3-p484
#RUN curl -sSL https://get.rvm.io | bash -s master --ruby=ruby-$RUBY_VERSION 

RUN mkdir -p /etc/puppet
RUN mkdir -p /usr/share/dtk

COPY dtk_modules /etc/puppet/modules
COPY docker/tenant.pp /tenant.pp

#RUN /etc/init.d/ssh start && /usr/local/bin/puppet apply --debug /usr/share/dtk/tasks/last-task/site-stage-1-invocation-1.pp
ADD docker/apply.sh apply.sh

RUN /apply.sh

COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN echo "daemon off;" >> /etc/nginx/nginx.conf

EXPOSE 22 443

ADD docker/init.sh init.sh
ADD docker/setup.sh setup.sh 

COPY docker/socket.conf /etc/nginx/conf.d/socket.conf

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD ["/setup.sh"]
