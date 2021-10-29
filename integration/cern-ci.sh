#!/bin/sh

# Exit in case of error
set -e

# Use the right python tool.
. /acc/local/share/python/acc-py/base/pro/setup.sh
python -V
pyver=$(python -c 'import sys; print("{}.{}".format(sys.version_info.major, sys.version_info.minor))')
echo "python version: $pyver"

# Check the variable is set
[ x"$CI_COMMIT_SHORT_SHA" != x ] || exit 1

localdir=/opt/home/cheby

base_destdir=/acc/local/share/ht_tools/noarch/cheby
if [ x"$CI_COMMIT_TAG" != x ]; then
    suffix=$CI_COMMIT_TAG
else
    suffix=$CI_COMMIT_SHORT_SHA
fi
destdir=$base_destdir/cheby-$suffix
prefix=$destdir/lib/python${pyver}/site-packages/
mkdir -p $prefix

export PYTHONPATH=$PYTHONPATH:$prefix
python3 ./setup.py install --prefix $destdir

# Update cheby-latest link
cd $base_destdir
ln -sfn cheby-$suffix cheby-latest

if [ x"$CI_COMMIT_TAG" = x ]; then
    # Remove the old version, unless it is the same as the current one
    # (could happen when re-running CI/CD: there is no new version and
    #  the current one shouldn't be removed).
    if [ -f last ]; then
        old=$(cat last)
        if [ "$old" != "$suffix" ]; then
            rm -rf ./cheby-$old
        fi
    fi
    echo $suffix > last
fi

#############
# DFS update
echo "$DFS_PASSWORD" | kinit cheby@CERN.CH 2>&1 > /dev/null

# Create an archive
tarfile="$localdir/cheby-${suffix}.tar"
tar cvf $tarfile cheby-$suffix

# Deploy it
smbclient -k //cerndfs.cern.ch/dfs/Applications/Cheby -Tx $tarfile

# Remove old version
smbclient -k //cerndfs.cern.ch/dfs/Applications/Cheby -c "rename cheby-latest cheby-old; rename cheby-$suffix cheby-latest; deltree cheby-old"

if [ x"$CI_COMMIT_TAG" != x ]; then
    # For tag commit, keep the tagged version.
    smbclient -k //cerndfs.cern.ch/dfs/Applications/Cheby -Tx $tarfile
fi

rm -f $tarfile

kdestroy
