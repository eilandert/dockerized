#!/bin/sh

TIME_STARTED="`date`"

dpkg-statoverride --remove /usr/bin/sudo

#rm -f /etc/apt/sources.list.d/ondrej-ppa.list

apt-get update
apt-get -y upgrade
apt-get -y install --no-install-recommends eatmydata ccache 
export LD_PRELOAD="${LD_PRELOAD:+$LD_PRELOAD:}libeatmydata.so"
PATH=/usr/lib/ccache:${PATH}

apt-get -y install git lsb-release libpcre3-dev zlib1g-dev build-essential unzip uuid-dev webp g++ libssl-dev wget curl sudo python-minimal rsync gperf

/usr/src/incubator-pagespeed-mod/install/install_required_packages.sh

. /etc/os-release ;\
apt-get -y -t ${VERSION_CODENAME}-backports upgrade ;\

mkdir -p ~/bin 
cd ~/bin 
git clone --depth=1 -c advice.detachedHead=false https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=$PATH:~/bin/depot_tools

cd /usr/src
if [ ! -d "incubator-pagespeed-mod" ]; then
    echo "cloning.."
    git clone -b latest-stable --depth=1 -c advice.detachedHead=false --recursive https://github.com/apache/incubator-pagespeed-mod.git
    cd incubator-pagespeed-mod
else
    echo "pulling.."
    cd incubator-pagespeed-mod
    git pull --recurse-submodules
fi

rm -rf /usr/src/incubator-pagespeed-mod/psol

NUMCORE=$(cat /proc/cpuinfo | grep -c core)
export NUMCORE
echo "NUMBER OF CORES: ${NUMCORE}"

python build/gyp_chromium --depth=.
tail -F /usr/src/incubator-pagespeed-mod/log/install_deps.log &
make -j${NUMCORE} BUILDTYPE=Release mod_pagespeed_test pagespeed_automatic_test
tail -F /usr/src/incubator-pagespeed-mod/log/psol_automatic_build.log &
install/build_psol.sh --skip_tests
rm -f /usr/src/psol.tar.gz
tar czf /usr/src/psol.tar.gz psol/

TIME_ENDED="`date`"

echo "Finished!"
echo "Started: ${TIME_STARTED}"
echo "Ended:   ${TIME_ENDED}"

echo "Dumped psol.tar.gz in /usr/src/psol.tar.gz"

ccache -s

exit 0;

