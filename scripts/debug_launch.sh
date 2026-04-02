#!/bin/sh
echo "ARGS: $@" > /tmp/steam_launch_args.txt
echo "PWD: $(pwd)" >> /tmp/steam_launch_args.txt
./run_bepinex.sh "$@" >> /tmp/steam_launch_args.txt 2>&1
