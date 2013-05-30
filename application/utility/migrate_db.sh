#!/bin/bash
/usr/lib/ruby/gems/1.8/gems/sequel-3.25.0/bin/sequel -m $(dirname $0)/../migrations postgres://postgres@localhost/$1