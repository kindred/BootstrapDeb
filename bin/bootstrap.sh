#!/bin/bash -eu
#
#set -xv

DIR="$( cd "$( dirname $0 )" && pwd )"
CONF="$DIR/../conf"
FUNC="$DIR/../funcs"

echo "Loading Bootstrap Config..." >&2
source $CONF/bootstrap.conf

echo "Loading Functions..." >&2
for FILE in $FUNC/*.conf
do
    echo "Loading `basename $FILE`..." >&2
    source $FILE
done

set -- `getopt -n$0 -u -a --longoptions="hostname: ip: password: arch: distro: mirror: timezone:" "h" "$@"` || usage
[ $# -eq 0 ] && usage

while [ $# -gt 0 ]
do
    case "$1" in
        --hostname)     HOSTNAME=$2;shift;;
        --ip)           IP=$2;shift;;
        --password)     PASSWORD=$2;shift;;
        --arch)         ARCH=$2;shift;;
        --distro)       DISTRO=$2;shift;;
        --mirror)       MIRROR=$2;shift;;
        --timezone)     TIMEZONE=$2;shift;;
        -h)             usage;;
        --)             shift;break;;
        -*)             usage;;
        *)              break;;            #better be the crawl directory
    esac
    shift
done

if [ -r $CONF/packages.conf ]
then
    echo "Loading Packages Config...." >&2
    source $CONF/packages.conf
fi

for p in $MAIN_MANIFEST
do
    # Call the methods
    eval $p
done

echo "Done"
exit

