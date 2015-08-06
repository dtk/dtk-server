FROM ubuntu:14.04
MAINTAINER dduvnjak <dario@atlantbh.com>

ENV HOME /root
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update -q
RUN apt-get install -y language-pack-en
RUN locale-gen en_US.UTF-8
RUN apt-get install -y \
  apt-transport-https ca-certificates \
  git cron \
  ruby ruby-dev \
  lsb-release openssh-server \
  sudo curl supervisor postgresql-client libxslt-dev

RUN mkdir -p /var/run/sshd

RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc
RUN gem install puppet -v 3.6.2

ENV RUBY_VERSION 1.9.3-p484
RUN curl -sSL https://get.rvm.io | bash -s master --ruby=ruby-$RUBY_VERSION
RUN /usr/local/rvm/wrappers/default/gem install bundler --no-rdoc --no-ri

RUN apt-get clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN env --unset=DEBIAN_FRONTEND
