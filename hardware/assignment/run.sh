#!/usr/bin/env sh
set -eu
ghdl -a --std=08 -fsynopsys $1.vhd
ghdl -a --std=08 -fsynopsys tb_$1.vhd
ghdl -e --std=08 -fsynopsys tb_$1
ghdl -r --std=08 -fsynopsys tb_$1 --wave=tb_$1.ghw
