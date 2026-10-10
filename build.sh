#!/bin/sh
# Packages the module into gboard-nightly-restart.zip
set -e
cd "$(dirname "$0")"
rm -f gboard-nightly-restart.zip
(cd module && zip -r9 ../gboard-nightly-restart.zip . -x '.*')
echo "Built gboard-nightly-restart.zip"
