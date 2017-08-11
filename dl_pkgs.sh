#!/usr/bin/bash

PROCESSORS=$(/usr/bin/getconf _NPROCESSORS_ONLN)
DEFAULT_RELEASE="test/26_Alpha"

if [ x$1 == x ]; then
    echo "No NVR file provided"
    echo
    echo "Usage `basename $0` <NVR file> [release]"
    echo
    echo "Default release: ${DEFAULT_RELEASE}"
    exit 1
else
    nvrfile=$(realpath $1)
fi

if [ x$2 == x ]; then
    release="${DEFAULT_RELEASE}"
else
    release=$2
fi

# Download all sources at same time
mkdir -p repo/$release/override/source-cache
pushd repo/$release/override/source-cache
cat $nvrfile | xargs --max-procs=$PROCESSORS -I NVR \
  koji download-build --arch=src NVR
popd


for arch in "x86_64" "i686" "armv7hl" "aarch64" "ppc64" "ppc64le" "s390x"; do
    mkdir -p repo/$release/override/$arch/os repo/$release/override/$arch/sources
    pushd repo/$release/override/$arch/os/
    cat $nvrfile | xargs --max-procs=$PROCESSORS -I NVR \
        koji download-build --arch=noarch --arch=$arch NVR
    popd
    cat $nvrfile | while read NVR
    do
        cp -f repo/$release/override/source-cache/$NVR.src.rpm repo/$release/override/$arch/sources/
    done
done

# Cleanup all our sources
rm -rf repo/$release/override/source-cache
