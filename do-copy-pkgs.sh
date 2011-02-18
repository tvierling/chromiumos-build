#!/bin/sh -e

basedir=$(cd $(dirname $0) && pwd -P)
tmp=$(mktemp -d tmp.copypkgs.XXXXXX)
trap "rm -rf $tmp" 0 1 2 15

pkgs=$( { cat <<-EOF
	app-arch/p7zip
	app-arch/unrar
	app-arch/unzip
	app-arch/zip
	app-editors/nano
	app-editors/vile
	app-misc/mc
	dev-libs/popt
	games-fps/doomsday
	media-libs/libsdl
	media-libs/sdl
	net-misc/rdesktop
	net-misc/rsync
	net-misc/socat
	net-misc/tigervnc
	www-client/lynx
EOF
} | sed 's,$,-*,' )

(cd ../chroot/build/x86-mario/packages && ln $pkgs $basedir/$tmp/)

rsync --rsync-path=.bin/local/rsync \
	-rtvP $basedir/$tmp/ www.duh.org:html/chromiumos/pkgs/
