#!/bin/sh

cd root || exit 1
scp -r . root@"$1":/
