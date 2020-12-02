#!/bin/sh

TIME_STARTED="`date`"

apt-get update
apt-get -y install git lsb-release libpcre3-dev zlib1g-dev build-essential unzip uuid-dev webp g++ libssl-dev wget curl sudo python-minimal rsync


mkdir -p ~/bin
cd ~/bin
git clone --depth=1 -c advice.detachedHead=false https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=$PATH:~/bin/depot_tools

cd /usr/src
if [ ! -d "incubator-pagespeed-mod" ]; then
    echo "cloning.."
    git clone -b latest-stable --depth=1 -c advice.detachedHead=false --jobs 10 --recursive https://github.com/apache/incubator-pagespeed-mod.git
    cd incubator-pagespeed-mod
else
    echo "pulling.."
    cd incubator-pagespeed-mod
    git pull --jobs 10 --recurse-submodules
fi

rm -rf /usr/src/incubator-pagespeed-mod/psol

python build/gyp_chromium --depth=.
make BUILDTYPE=Release mod_pagespeed_test pagespeed_automatic_test
install/build_psol.sh --skip_tests
rm -f /usr/src/psol.tar.gz
tar czf /usr/src/psol.tar.gz psol/

TIME_ENDED="`date`"

echo "Finished!"
echo "Started: ${TIME_STARTED}"
echo "Ended:   ${TIME_ENDED}"

echo "Dumped psol.tar.gz in /usr/src/psol.tar.gz"


exit 0;

