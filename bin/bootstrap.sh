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

TEMP=`mktemp`
. etc/config.sh
. etc/functions.sh

showSettings

(
#echo $((1 / 0))
#false # cause error
    doMountingFS                    1 "Mounting Filesystems"

    doBootstrap                     2 "Bootstrapping OS Image"
    doSecondStageBootstrap          10 "Running Second Stage Bootstrap"
    doMountProc                     20 "Mounting Proc"
    doCreateDev                     25 "Creating Dev"

#sudo mkdir /home/rklose/robotOS/grip/dev/pts
#echo "Mounting Dev Pts"
#sudo mount -t devpts devpts /home/rklose/robotOS/grip/dev/pts

    doGenerateMtab                  30 "Generating mtab"
    doSetupHostnameResolvHosts      35 "Setting up hostname, resolv and hosts"
    doSetupAptSources               37 "Setting up Apt Sources"
    doSysCtl                        40 "Setting up SysCtl"
    doSetupLocale                   43 "Setting up locale"
    #doSetupPackages                 45 "Setting up packages"
    doSetupMRPackages               47 "Installing MR Packages"
    doCreatingMRadminUser           50 "Creating mradmin user"
    doCreatingMarathonDirectories   55 "Creating marathon directories"
    doCreatingFilesystemTable       60 "Creating Filesystem table"
    doCreatingNetworkInterfaces     65 "Creating Network Interfaces"
    doCreatingWPASupplicant         70 "Creating Wpa Supplicant"
    #####doInstallingKernel              75 "Installing the Kernel"
    doInstallingGrub                80 "Installing Grub"
    doUpdatingSudoers               82 "Updating Sudoers"

#echo "Unmounting Dev Pts"
#sudo umount /home/rklose/robotOS/grip/dev/pts

#echo "Unmounting Dev"
#sudo umount /home/rklose/robotOS/grip/dev

    doUnmountingProc                84 "Unmounting Proc"
    doRemovingPersistentNetRules    85 "Removing Persistent Net Rules"
    doSetSerialDevices              86 "Setting Serial Devices"

    doCleanup                       87 "Cleaning up..."

    doUnmountingFS                  88 "Unmounting FS"

    set +e
    doFSCKPartition                 89 "/dev/sdb1"
    doFSCKPartition                 91 "/dev/sdb2"
    doFSCKPartition                 93 "/dev/sdb5"
    doFSCKPartition                 95 "/dev/sdb6"
    doFSCKPartition                 97 "/dev/sdb7"
    if [ "$SWAP" = "on" ]; then
        doFSCKPartition                 99 "/dev/sdb9"
    else
        doFSCKPartition                 99 "/dev/sdb8"
    fi
    set -e

    doSetVersion

    progress 100 "Game Over Man"
    echo "Completed" | sudo tee -a $LOG
    sleep 1
) | dialog --title "Creating OS Image" --guage "Please wait..." 10 60 0

#echo "Is there an error: $?"
#exit
#if [ $? != 0 ]; then
#	echo "ERROR: Something failed... Check logs."
#	exit 1
#fi
#exit

dialog --msgbox "Game Over Man!
    _.  ._
   / \  / \\
  /  /\/  /\\
 /  / /  / /\\
(__/\/__/\/__)


Build finished.

Next steps:
  - Patch Robot
  - Remount / as Read/Write
  - Run manage configs as mrsys user
  - Reboot Robot

- Skynet" 0 0

exit

