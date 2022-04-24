#!/bin/sh

#part1
printf '\033c'

echo -e "\e[32m  Preparing Disk and Filesystems for installation ...\e[0m"
mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

echo -e "\e[32m  Doing the base installation ...\e[0m"
REPO=https://alpha.de.repo.voidlinux.org/current/musl
ARCH=x86_64-musl
mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/
XBPS_ARCH=$ARCH xbps-install -Sy -r /mnt -R "$REPO" base-minimal bash openssl eudev dhcpcd neovim e2fsprogs wget grub
wget https://github.com/LaithOsama/kernel/raw/main/linux5.16-5.16.18_1.x86_64-musl.xbps
xbps-rindex --add linux5.16-5.16.18_1.x86_64-musl.xbps
XBPS_ARCH=$ARCH xbps-install -r /mnt --repository /root/ -y linux5.16
echo -e "\e[32m  Entering the Chroot ...\e[0m"
mount --rbind /sys /sys && mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc
cp /etc/resolv.conf /mnt/etc/
sed '1,/^#part2$/d' void-musl-install.sh > /mnt/void-install2.sh
chmod +x /mnt/void-install2.sh
PS1='(chroot) # ' chroot /mnt /bin/bash ./void-install2.sh
exit 

#part2
printf '\033c'

echo -e "\e[32m  Configuring fstab ...\e[0m"
cp /proc/mounts /etc/fstab
nvim /etc/fstab
echo "tmpfs    /tmp     tmpfs   defaults,nosuid,nodev   0 0" >> /etc/fstab

echo -e "\e[32m  Setting up localtime and hostname ... etc.\e[0m"
ln -sf /usr/share/zoneinfo/Asia/Baghdad /etc/localtime
echo "laptop" > /etc/hostname
nvim /etc/rc.conf

echo -e "\e[32m  Grub installation ...\e[0m"
grub-install /dev/sda
echo 'GRUB_CMDLINE_LINUX="root=/dev/sda2 rootfstype=ext4"' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\e[32m  Install Packages ...\e[0m"
xbps-install -Sy xorg-minimal gcc make pkg-config libXft-devel libX11-devel libXinerama-devel xdpyinfo \
hsetroot sxiv zathura zathura-pdf-mupdf maim xset xrandr xclip qutebrowser git redshift python3-adblock \
mpv cmus cmus-opus cmus-flac newsboat unzip wget calcurse yt-dlp xdotool dosfstools curl lf ueberzug \
zsh transmission setxkbmap xmodmap xcape mdocml pfetch fzf bat jq bc xz picom opendoas dejavu-fonts-ttf slock \
htop alsa-utils xbacklight unclutter-xfixes st-terminfo zsh-autosuggestions

echo -e "\e[32m  Install intel drivers ...\e[0m"
xbps-install -y xf86-video-intel mesa-vaapi libva-intel-driver
rm -rf /var/cache/xbps/*

echo -e "\e[32m  Setting up users, mouse speed, keyboard langs ... etc.\e[0m"
passwd
echo "permit nopass :wheel" >> /etc/doas.conf
useradd -m -G wheel -s /bin/zsh laith
usermod -g audio laith
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

echo -e "\e[32m  Enabling and Disabling services ...\e[0m"
ln -s /etc/sv/alsa /etc/runit/runsvdir/default/
ln -s /etc/sv/dhcpcd /etc/runit/runsvdir/default/
rm -rf /etc/sv/agetty-tty3
rm -rf /etc/sv/agetty-tty4
rm -rf /etc/sv/agetty-tty5
rm -rf /etc/sv/agetty-tty6

vi3_path=/home/laith/void-install3.sh
sed '1,/^#part3$/d' void-install2.sh > $vi3_path
chown laith:laith $vi3_path
chmod +x $vi3_path
su -c $vi3_path -s /bin/bash laith
exit

#part3
printf '\033c'
cd $HOME
rm -rf *.* .*

echo -e "\e[32m  Downloading and managing dotfiles ...\e[0m"
git clone https://github.com/LaithOsama/.dotfiles.git 
mv .dotfiles/.* ~ && rm -rf .git .dotfiles

echo -e "\e[32m  Install dwm, st, slstatus and dmenu (Suckless Tools) ...\e[0m"
git clone --depth=1 https://github.com/LaithOsama/dwm.git ~/.local/src/dwm
doas make -C ~/.local/src/dwm install
git clone --depth=1 https://github.com/LaithOsama/st.git ~/.local/src/st
doas make -C ~/.local/src/st install
doas xbps-install fribidi-devel
git clone --depth=1 https://github.com/LaithOsama/dmenu.git ~/.local/src/dmenu
doas make -C ~/.local/src/dmenu install
git clone --depth=1 https://github.com/LaithOsama/slstatus.git ~/.local/src/slstatus
doas make -C ~/.local/src/slstatus install

echo -e "\e[32m  We're almost done, don't forget to curse the neo-liberal regimes and America :)\e[0m"
doas git clone https://github.com/zdharma-continuum/fast-syntax-highlighting /usr/share/zsh/plugins/fast-syntax-highlighting
git clone https://github.com/pystardust/ytfzf
doas make -C ~/ytfzf install doc; rm -rf ytfzf
mkdir -p ~/.cache/zsh ~/data ~/dl/git
touch ~/.cache/zsh/history
exit
