#!/bin/sh -e

cd $(dirname $0)
TOOLDIR=$(pwd -P)
cd ..
TOP=$(pwd -P)

export BOARD=x86-generic

if ! grep -q chromiumos-overlay/chromeos /etc/debian_chroot 2>/dev/null; then
	echo "(entering chroot...)"
	cd src/scripts
	exec ./enter_chroot.sh -- ../../$(basename $TOOLDIR)/$(basename $0) "$@"
fi

##### build #####

cd $TOP/src/scripts

#./build_packages --board=x86-generic --jobs=4 --nousepkg --nowithautotest --nowithtest \
	# --oldchromebinary

#./build_image --board=x86-generic --withdev --noenable_rootfs_verification

./image_to_vm.sh --board=x86-generic \
	$TOP/src/build/images/$BOARD/latest/chromiumos_image.bin
