#!/bin/bash
# lxgames-build.sh -- creates an LXgames LiveCD ISO, based on lubuntu-build.sh
# Author: Thanh Nguyen <thanhnguyen@mbm.vn>
# Based heavily on HOWTO information by 
#   Julien Lavergne <gilir@ubuntu.com>
# Version: 20110303

set -eu				# Be strict

# Script parameters: arch mirror gnomelanguage release
# Arch to build ISO for, i386 or amd64
arch=${1:-i386}
# Ubuntu mirror to use
mirror=${2:-"http://192.168.1.200:3142/ubuntu.ctu.edu.vn/archive"}
# Set of GNOME language packs to install.
#   Use '\*' for all langs, 'en' for English.
# Install language with the most popcon
gnomelanguage=${3:-'{en}'}	#
# Release name, used by debootstrap.  Examples: lucid, maverick, natty.
release=${4:-oneiric}

# Necessary data files
datafiles="image-${arch}.tar.lzma sources.list"
# Necessary development tool packages to be installed on build host
devtools="debootstrap genisoimage p7zip-full squashfs-tools ubuntu-dev-tools"

# Make sure we have the data files we need
for i in $datafiles
do
  if [ ! -f $i ]; then
    echo "$0: ERROR: data file `pwd`/$i not found"
    exit 1
  fi
done

# Make sure we have the tools we need installed
sudo apt-get -q install $devtools -y --no-install-recommends

# Create and populate the chroot using debootstrap
[ -d chroot ] && sudo rm -R chroot/
# Debootstrap outputs a lot of 'Information' lines, which can be ignored
sudo debootstrap --arch=${arch} ${release} chroot ${mirror} # 2>&1 |grep -v "^I: "
# Use /etc/resolv.conf from the host machine during the build
sudo cp -v /etc/resolv.conf chroot/etc/resolv.conf

# Copy the source.list to enable universe / multiverse in the chroot, and eventually additional repos.
sudo cp -v sources.list chroot/etc/apt/sources.list

# Work *inside* the chroot
sudo chroot chroot <<EOF
# Mount needed three pseudo-filesystems
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts

# Set up several useful shell variables
export CASPER_GENERATE_UUID=1
export HOME=/root
export TTY=unknown
export TERM=vt100
export DEBIAN_FRONTEND=noninteractive
export LANG=C
export LIVE_BOOT_SCRIPTS="casper lupin-casper"

#  To allow a few apps using upstart to install correctly. JM 2011-02-21
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

# Add key for third party repo
#apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CF57B0F4
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E1098513

# Update in-chroot package database
apt-get -q update

# Install core packages
apt-get -q -y --purge install ubuntu-standard casper lupin-casper \
  laptop-detect os-prober linux-generic

# Install base packages
apt-get -q -y --purge install --no-install-recommends lubuntu-default-settings \
  lxsession lightdm lightdm-gtk-greeter lubuntu-artwork plymouth-theme-lubuntu-logo \
  plymouth-theme-lubuntu-text lubuntu-icon-theme \
  network-manager-gnome xorg dbus-x11 openbox ubiquity-frontend-gtk

# Install specific packages
apt-get -q -y --purge install lxgames-default-session chromium-browser lxlauncher 

# Install lxrandr to change monitor settings
apt-get -q -y --purge install lxrandr

# Install games
apt-get -q -y --purge install openttd frozen-bubble supertux pokerth \
  armagetronad glchess gnomine gnome-mahjongg aisleriot freecol gnome-sudoku freeciv-client-gtk
apt-get -q -y --purge install smc gnotski gbrainy zaz

## A
apt-get -q -y --purge install abe abuse asc alex4 alienblaster amoebax armagetronad 

## B
apt-get -q -y --purge install ballz wesnoth btanks beneath-a-steel-sky blobwars bombardier boswars bygfoot \

## C
apt-get -q -y --purge install granatier crack-attack criticalmass crossfire-client crossfire-server 

## D 
apt-get -q -y --purgeinstall dodgindiamond2 

## C
apt-get -q -y --purge install egoboo enigma efp extremetuxracer 

## F
apt-get -q -y --purge install kblocks fillets-ng flight-of-the-amazon-queen foobillard freeciv-client-gtk freeciv-server \
  freecol freedoom freedroid frozen-bubble 

## G
apt-get -q -y --purge install gcompris gemdropx gl-117 gnubg sopwith gweled 

## H
apt-get --q -y --purge install hedgewars 

## K
apt-get -q -y --purge install kcheckers knights kobodeluxe 

## L
apt-get -q -y --purge install lincity-ng liquidwar lmarbles londonlaw lordsawar

## M
apt-get -q -y --purge install maelstrom magicor mana mirrormagic

## N
apt-get -q -y --purge install nethack-x11 netpanzer neverball neverputt

## O

## P
apt-get -q -y --purge install pachi pinball pingus pioneers pipenightdreams planets \
  powermanga pychess pysolfc 
  
## Q
apt-get -q -y --purge install quarry 

## R
apt-get -q -y --purge install ri-li rocksndiamonds

## S
apt-get -q -y --purge install scorched3d scummvm solarwolf stormbaancoureur supertux supertuxkart

## T 
apt-get -q -y --purge install tecnoballz torcs trackballs tuxtype tremulous

## U

## V
apt-get -q -y --purge install vodovod 

## W
apt-get -q -y --purge install warmux warzone2100 widelands

## X
apt-get -q -y --purge install xblast xgalaga xmoto

## Z

  
# Install additional packages, only for the lice-cd (should be removed when creating the manifest)
apt-get -q -y --purge install pptp-linux ndiswrapper-utils-1.9 ndisgtk \
  linux-wlan-ng libatm1 setserial b43-fwcutter \
  linux-headers-generic
  
# Install GDM to fix ubiquity issue
apt-get -q -y --purge install gdm
apt-get -q -y --purge remove gdm

# Install languages packs
apt-get -q -y --purge install language-pack-{en}

apt-get -q -y --purge install language-pack-gnome-${gnomelanguage}

# Clean up the chroot before
perl -i -nle 'print unless /^Package: language-(pack|support)/ .. /^$/;' /var/lib/apt/extended_states
apt-get clean
rm -rf /tmp/*
rm /etc/resolv.conf

# Reverting earlier initctl override. JM 2012-0604
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

# Unmount pseudo-filesystems within chroot
umount -lf /proc
umount -lf /sys
umount -lf /dev/pts
exit

EOF

###############################################################
# Continue work outside the chroot, preparing image
echo $0: Preparing image...

[ -d image ] && sudo /bin/rm -r image
tar xf image-${arch}.tar.lzma

# Copy the kernel from the chroot into the image for the LiveCD
sudo cp chroot/boot/vmlinuz-3.*.**-**-generic image/casper/vmlinuz
sudo cp chroot/boot/initrd.img-3.*.**-**-generic image/casper/initrd.lz

# Extract initrd and update uuid configuration
7z e image/casper/initrd.lz && \
  mkdir initrd_FILES/ && \
  mv initrd initrd_FILES/ && \
  cd initrd_FILES/ && \
  cpio -id < initrd && \
  cd .. && \
  cp initrd_FILES/conf/uuid.conf image/.disk/casper-uuid-generic && \
  rm -R initrd_FILES/

# Fix old version and date info in .hlp files
newversion="11.10"		# Should be derived from releasename $4 FIXME
for oldversion in 10.04 10.10 11.04
do
  sed -i -e "s/${oldversion}/${newversion}/g" image/isolinux/*.hlp image/isolinux/f1.txt
done
newdate=$(date -u +%Y%m%d)
for olddate in 20100113 20100928
do
  sed -i -e "s/${olddate}/${newdate}/g" image/isolinux/*.hlp image/isolinux/f1.txt
done

# Create filesystem manifests
sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' >/tmp/manifest.$$
sudo cp -v /tmp/manifest.$$ image/casper/filesystem.manifest
sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
rm /tmp/manifest.$$

# Remove packages from filesystem.manifest-desktop 
#  (language and extra for more hardware support)
REMOVE='gparted ubiquity ubiquity-frontend-gtk casper live-initramfs user-setup discover1 
 xresprobe libdebian-installer4 pptp-linux ndiswrapper-utils-1.9 
 ndisgtk linux-wlan-ng libatm1 setserial b43-fwcutter 
 linux-headers-generic indicator-session indicator-application 
 language-pack-*'
for i in $REMOVE 
do
    sudo sed -i "/${i}/d" image/casper/filesystem.manifest-desktop
done

# Now squash the live filesystem
echo "$0: Starting mksquashfs at $(date -u) ..."
sudo mksquashfs chroot image/casper/filesystem.squashfs -noappend -no-progress
echo "$0: Finished mksquashfs at $(date -u )"

# Generate md5sum.txt checksum file 
cd image && sudo find . -type f -print0 |xargs -0 sudo md5sum |grep -v "\./md5sum.txt" >md5sum.txt

# Generate a small temporary ISO so we get an updated boot.cat
IMAGE_NAME=${IMAGE_NAME:-"X-Mario ${release} $(date -u +%Y%m%d) - ${arch}"}
ISOFILE=xmario-${release}-$(date -u +%Y%m%d)-${arch}.iso
sudo mkisofs -r -V "$IMAGE_NAME" -cache-inodes -J -l \
  -b isolinux/isolinux.bin -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  --publisher "X-Mario Packaging Team" \
  --volset "Ubuntu Linux http://www.ubuntu.com" \
  -p "${DEBFULLNAME:-$USER} <${DEBEMAIL:-on host $(hostname --fqdn)}>" \
  -A "$IMAGE_NAME" \
  -m filesystem.squashfs \
  -o ../$ISOFILE.tmp .

# Mount the temp ISO and copy boot.cat out of it
tempmount=/tmp/$0.tempmount.$$
mkdir $tempmount
loopdev=$(sudo losetup -f)
sudo losetup $loopdev ../$ISOFILE.tmp
sudo mount -r -t iso9660 $loopdev $tempmount
sudo cp -vp $tempmount/isolinux/boot.cat isolinux/
sudo umount $loopdev
sudo losetup -d $loopdev
rmdir $tempmount

# Generate md5sum.txt checksum file (now with new improved boot.cat)
sudo find . -type f -print0 |xargs -0 sudo md5sum |grep -v "\./md5sum.txt" >md5sum.txt

# Remove temp ISO file
sudo rm ../$ISOFILE.tmp

# Create an X-Mario ISO from the image directory tree
sudo mkisofs -r -V "$IMAGE_NAME" -cache-inodes -J -l \
  -b isolinux/isolinux.bin -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  --publisher "X-Mario Packaging Team" \
  --volset "Ubuntu Linux http://www.ubuntu.com" \
  -p "${DEBFULLNAME:-$USER} <${DEBEMAIL:-on host $(hostname --fqdn)}>" \
  -A "$IMAGE_NAME" \
  -o ../$ISOFILE .

# Fix up ownership and permissions on newly created ISO file
sudo chown $USER:$USER ../$ISOFILE
chmod 0444 ../$ISOFILE

# Create the associated md5sum file
cd ..
md5sum $ISOFILE >${ISOFILE}.md5
