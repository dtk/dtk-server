#!/usr/bin/env bash

chown -R dtk1:dtk1 /home/dtk1
chown -R git1:git1 /home/git1

if [[ -s /dtk-creds/creds ]]; then
  su - 'dtk1' -c 'bash /init.sh'
  cat /dev/null > /dtk-creds/creds
fi

rm -rf /var/run/nginx/nginx.sock

/usr/bin/supervisord
