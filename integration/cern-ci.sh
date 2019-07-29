#!/bin/sh

# Exit in case of error
set -e

# Use the right python tool.
. /acc/local/share/python/L867/setup.sh
python -V

[ x"$CI_COMMIT_SHORT_SHA" != x ] || exit 1

base_destdir=/acc/local/share/ht_tools/noarch/cheby
destdir=$base_destdir/cheby-$CI_COMMIT_SHORT_SHA
prefix=$destdir/lib/python3.6/site-packages/
mkdir -p $prefix

export PYTHONPATH=$PYTHONPATH:$prefix
python3 ./setup.py install --prefix $destdir
