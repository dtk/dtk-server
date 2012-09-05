#!/bin/bash
/var/lib/gems/1.8/bin/sequel -m $(dirname $0)/../migrations postgres://postgres@localhost/db_main