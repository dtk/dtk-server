#!/bin/bash
sequel -m $(dirname $0)/../migrations postgres://postgres@localhost/$1