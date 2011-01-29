#!/bin/sh
echo "delete from context.context where id=2; insert into context.context (id) select 2;" | psql -U postgres db_main

