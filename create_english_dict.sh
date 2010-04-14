#!/bin/sh

strings /usr/lib/aspell-*/en-common.rws | egrep '^[A-Za-z]*$' | tr A-Z a-z | ./names.lua -m 1 -c zero -o config_en.lua
