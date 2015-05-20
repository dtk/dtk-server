#!/usr/bin/env bash

/usr/sbin/sshd -D &

/usr/local/bin/puppet apply --debug /tenant.pp
