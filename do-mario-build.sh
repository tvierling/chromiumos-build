#!/bin/sh -e

cd $(dirname $0)
TOOLDIR=$(pwd -P)
cd ..
TOP=$(pwd -P)

export BOARD=$(cat $TOP/src/scripts/.default_board)

if ! grep -q chromiumos-overlay/chromeos /etc/debian_chroot 2>/dev/null; then
	echo "(entering chroot...)"
	cd src/scripts
	exec ./enter_chroot.sh -- ../../$(basename $TOOLDIR)/$(basename $0) "$@"
fi

##### build #####

export CHROMEOS_VERSION_DEVSERVER=http://chromiumos.duh.org:8080
export CHROMEOS_VERSION_AUSERVER=http://chromiumos.duh.org:8080/update

cd $TOP/src/scripts

if [ "$1" != "copy" ]; then
	(
		./build_packages --jobs=4 --nousepkg --nowithautotest --nowithtest \
			# --oldchromebinary

		./build_image --withdev --noenable_rootfs_verification

		./mod_image_for_recovery.sh --nominimize_image \
			--kernel_image $TOOLDIR/mario_recovery_kernel.bin \
			--image $TOP/src/build/images/$BOARD/latest/chromiumos_image.bin
	) 2>&1 | tee $TOP/build.out
fi

##### generate logs #####

cd $TOP/src/build/images/$BOARD/latest

ver=$(basename $(pwd -P))

if [ "$1" != "copy" ]; then
	if [ -f "duh-$ver.buildlog.gz" ]; then
		echo 'buildlog already exists; build failed above!' >&2
		exit 1
	fi

	sed -e 's,atl\.damballa,intranet\.duh\.org,g' $TOP/build.out >duh-$ver.buildlog
	gzip -9 duh-$ver.buildlog

	grep '^\[.*to .*/rootfs/' $TOP/build.out | cut -c17- | cut -f1 -d' ' | sort -u >duh-$ver.pkglist

	#prev=$(ls -1tr .. | grep -v latest | tail -2 | head -1)
	prev=$(ls -1 .. | grep -v latest | tail -2 | head -1)
	(cd .. && diff -U0 $prev/duh-$prev.pkglist $ver/duh-$ver.pkglist) >duh-$ver.pkglist.diff || true

	(cd $TOP/src/overlays && git diff cros/master) | gzip -9c >duh-$ver.src-overlays.diff.gz
	(cd $TOP/src/scripts && git diff cros/master) | gzip -9c >duh-$ver.src-scripts.diff.gz
	(cd $TOP/src/third_party/chromiumos-overlay && git diff cros/master) | gzip -9c >duh-$ver.src-chromiumos-overlay.diff.gz
	(cd $TOP/src/third_party/portage && git diff cros/master) | gzip -9c >duh-$ver.src-portage.diff.gz

	rm -f chromiumos_*.bin

	mv recovery_image.bin duh-$ver.bin
	zip -9m duh-$ver.zip duh-$ver.bin
	md5sum duh-$ver.zip >duh-$ver.zip.md5
fi

##### upload #####

if [ "$1" != "nocopy" ]; then
	set -x

	ssh www.duh.org "cd html/chromiumos/cr-48 && mkdir $ver"

	scp $TOOLDIR/HEADER.html duh-$ver.* www.duh.org:html/chromiumos/cr-48/$ver/
fi
