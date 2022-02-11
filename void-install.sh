#!/bin/sh

#part1
printf '\033c'

echo -e "\e[32m  Preparing Disk and Filesystems for installation ..."
mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

echo -e "\e[32m  Doing the base installation ..."
REPO=https://alpha.de.repo.voidlinux.org/current/musl
ARCH=x86_64-musl
mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/
XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-minimal linux5.10 base-files bash openssh dhcpcd \
e2fsprogs dracut ethtool iputils usbutils pciutils ncurses grub os-prober ntfs-3g

echo -e "\e[32m  Doing some configuration ..."
mkdir -pv /mnt/etc/sysctl.d
echo"
vm.vfs_cache_pressure=500
vm.swappiness=100
vm.dirty_background_ratio=1
vm.dirty_ratio=50" >> /mnt/etc/sysctl.d/00-sysctl.conf
mkdir -pv /mnt/etc/modprobe.d
echo"
# Disable watchdog
install iTCO_wdt /bin/true
install iTCO_vendor_support /bin/true
# Disable Camera
blacklist uvcvideo
# Disable Bluetooth
blacklist btusb
blacklist btrtl
blacklist btbcm
blacklist btintel
blacklist bluetooth
# Disable Wi-Fi
blacklist iwlwifi
# Disable nouveau
blacklist nouveau
# Disable sound over HDMI
blacklist snd_hdmi_lpe_audio" >> /mnt/etc/modprobe.d/blacklist.conf

echo -e "\e[32m  Entering the Chroot ..."
mount --rbind /sys /mnt/sys && mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc
cp /etc/resolv.conf /mnt/etc/
sed '1,/^#part2$/d' void-install.sh > /mnt/void-install2.sh
chmod +x /mnt/void-install2.sh
PS1='(chroot) # ' chroot /mnt /bin/bash ./void-install2.sh
exit 

#part2
printf '\033c'

echo -e "\e[32m  Configuring fstab ..."
cp /proc/mounts /etc/fstab
blkid /dev/sda2 >> /etc/fstab
blkid /dev/sda1 >> /etc/fstab
blkid /dev/sda3 >> /etc/fstab
nvim /etc/fstab
echo "tmpfs    /tmp     tmpfs   defaults,nosuid,nodev   0 0" >> /etc/fstab

echo -e "\e[32m  Setting up swapfile, localtime and hostname ... etc."
dd if=/dev/zero of=/swapfile bs=1G count=8 status=progress
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab 
ln -sf /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
echo hostonly=yes >> /etc/dracut.conf
echo "laptop" > /etc/hostname

echo -e "\e[32m  Grub installation ..."
grub-install /dev/sda
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\e[32m  Install Packages ..."
xbps-install -Sy xorg-minimal gcc make pkg-config libXft-devel libX11-devel libXinerama-devel \
xwallpaper sxiv zathura zathura-pdf-mupdf stow maim xset xrandr xclip pcmanfm firefox-esr git \
mpv cmus cmus-opus cmus-flac newsboat unzip wget calcurse yt-dlp xdotool dosfstools \
zsh transmission man-db pfetch fzf bc picom opendoas cantarell-fonts \
htop alsa-utils void-repo-nonfree && xbps-install -Sy unrar

echo -e "\e[32m  Install intel drivers ..."
xbps-install -y xf86-video-intel mesa intel-ucode libva-intel-driver intel-video-accel linux-firmware-intel
read -p "Do you need extra packages like libreoffice, kodi and some games ? [y/N]" answer
if [[ $answer = y ]] ; then
  xbps-install -y libreoffice-calc fractal kodi supertuxkart sauerbraten
fi
rm -rf /var/cache/xbps/*

echo -e "\e[32m  Setting up users, mouse speed, keyboard langs ... etc."
passwd
echo "permit nopass :wheel" >> /etc/doas.conf
useradd -m -G wheel -s /bin/zsh laith
passwd laith
mkdir -pv /etc/X11/xorg.conf.d
echo 'Section "InputClass"
	Identifier "My Mouse"
	MatchIsPointer "yes"
	Option "AccelerationProfile" "-1"
	Option "AccelerationScheme" "none"
	Option "AccelSpeed" "-1"
EndSection' >> /etc/X11/xorg.conf.d/50-mouse-acceleration.conf
echo 'Section "InputClass"
  	Identifier "system-keyboard"
  	MatchIsKeyboard "on"
  	Option "XkbLayout" "us,ar"
  	Option "XkbModel" "pc105"
  	Option "XkbVariant" ",qwerty"
  	Option "XkbOptions" "grp:win_space_toggle"
EndSection' >> /etc/X11/xorg.conf.d/00-keyboard.conf
echo 'Section "Device"
	Identifier "Intel Graphics"
	Driver "modesetting"
EndSection' >> /etc/X11/xorg.conf.d/20-intel.conf
wget https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts
doas cat hosts >> /etc/hosts && rm hosts

echo -e "\e[32m  Making sure that all installed packages are configured properly ..."
xbps-reconfigure -fa

echo -e "\e[32m  Enabling services ..."
ln -s /etc/sv/alsa /etc/runit/runsvdir/default/
ln -s /etc/sv/dhcpcd /etc/runit/runsvdir/default/
vi3_path=/home/laith/void-install3.sh
sed '1,/^#part3$/d' void-install2.sh > $vi3_path
chown laith:laith $vi3_path
chmod +x $vi3_path
su -c $vi3_path -s /bin/sh laith
exit

#part3
printf '\033c'
cd $HOME
rm -rf *.* .*

echo -e "\e[32m  Downloading and managing dotfiles ..."
git clone https://github.com/LaithOsama/.dotfiles.git 
cd .dotfiles && stow .
cd ..

echo -e "\e[32m  Install dwm, st, slstatus and dmenu (Suckless Tools) ..."
git clone --depth=1 https://github.com/LaithOsama/dwm.git ~/.local/src/dwm
doas make -C ~/.local/src/dwm install
git clone --depth=1 https://github.com/LaithOsama/st.git ~/.local/src/st
doas make -C ~/.local/src/st install
git clone --depth=1 https://github.com/LaithOsama/dmenu.git ~/.local/src/dmenu
doas make -C ~/.local/src/dmenu install
git clone --depth=1 https://github.com/LaithOsama/slstatus.git ~/.local/src/slstatus
doas make -C ~/.local/src/slstatus install

echo -e "\e[32m  We're almost done, don't forget to curse the neoliberal regimes and America :)"
doas git clone https://github.com/zdharma-continuum/fast-syntax-highlighting /usr/share/zsh/plugins/fast-syntax-highlighting
mkdir -p ~/.cache/zsh ~/data ~/dl/git
touch ~/.cache/zsh/history
exit
