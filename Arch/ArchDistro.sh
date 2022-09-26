#!/bin/bash
# author: eleAche
: '
    Instalacion de arch linux desde la bios. (arch base)
    Este script esta en proceso de testing. 


'
set -e

## Parametros de instalacion
DISKLABEL='DOS'
HOSTNAME="Markov"
IN_DEVICE=/dev/sda
default_keymap='es'
BOOT_DEVICE="${IN_DEVICE}1"
EXTN_DEVICE="${IN_DEVICE}2"
HOME_DEVICE="${IN_DEVICE}5" 
SWAP_DEVICE="${IN_DEVICE}6"
ROOT_SIZE=80G
SWAP_SIZE=16G
HOME_SIZE=100G
EXTN_SIZE=120G
TIME_ZONE="$(curl http://geoip.ubuntu.com/lookup | sed -n -e 's/.*<TimeZone>\(.*\)<\/TimeZone>.*/\1/p')"
TIME_ZONE=${TIME_ZONE:="America/Monterrey"}
LOCALE="en_US.UTF-8"
FILESYSTEM=ext4
BASE_SYSTEM=( base linux linux-firmware nano grub networkmanager dhcpcd netctl wpa_supplicant dialog )
BASIC_X=( xorg-server xorg-xinit gdm i3 tilix i3-gaps i3status i3blocks feh terminator ttf-font-awesome ttf-ionicons git nodejs npm npm-check-updates ruby)
all_pkgs=( BASE_SYSTEM BASIC_X )

## Funciones
    format_it(){
    device=$1; fstype=$2
    mkfs."$fstype" "$device" && echo " $device format!" || error "format_it(): Can't format device $device with $fstype" 
}

    mount_it(){
        device=$1; mt_pt=$2
        mount "$device" "$mt_pt" && echo "$device mount!" || error "mount_it(): Can't mount $device to $mt_pt"
}
    formatparts() {
# comandos para sfdisk ######
cat > /tmp/sfdisk.cmd << EOF
$ROOT_DEVICE : start= 2048, size=+$ROOT_SIZE, type=83, bootable
$EXTN_DEVICE : size=+$EXTN_SIZE, type=05
$HOME_DEVICE : size=+$HOME_SIZE, type=83
$SWAP_DEVICE : size=+$SWAP_SIZE, type=82
EOF
###### comandos para sfdisk #
sfdisk "$IN_DEVICE" < /tmp/sfdisk.cmd 
sleep 10s && partprobe /dev/sda
format_it "$ROOT_DEVICE" "$FILESYSTEM"
mount_it "$ROOT_DEVICE" /mnt
format_it "$HOME_DEVICE" "$FILESYSTEM"
mkdir /mnt/home
mount_it "$HOME_DEVICE" /mnt/home
mkswap "$SWAP_DEVICE" && swapon "$SWAP_DEVICE"
echo "yes! waiting" && sleep 20s
}
    tmproot(){
        arch-chroot /mnt "$@"
        echo -e "\e[1;31;40m ${@} \e[m"
}
    setuphosts() { 
cat > /mnt/etc/hosts << HOSTS
127.0.0.1      localhost
::1            localhost
127.0.1.1      $HOSTNAME.localdomain     $HOSTNAME
HOSTS
}

## Rutina de pre-instalacion
echo -e "\n\nWaiting until reflector has finished updating mirrorlist..."
while true; do
    pgrep -x reflector &>/dev/null || break
    echo -n '.'
    sleep 2
done
echo -e "\n\nTesting internet connection..."
$(ping -c 3 archlinux.org &>/dev/null) || (echo "Not Connected to Network!!!" && exit 1)
echo "Good!  We're connected!!!" && sleep 3


##########################################
##        SCRIPT STARTS HERE
##########################################

loadkeys "${default_keymap}"
formatparts
pacstrap /mnt "${BASE_SYSTEM[@]}"
genfstab -U /mnt >> /mnt/etc/fstab
tmproot ln -sf /usr/share/zoneinfo/"$TIME_ZONE" /etc/localtime
tmproot hwclock --systohc --utc
echo "LANG=$LOCALE" > /mnt/etc/locale.conf && export LANG="$LOCALE"
echo "KEYMAP=es" > /etc/vconsole.conf
echo "$HOSTNAME" > /mnt/etc/hostname && setuphosts
tmproot sed -i "s/#$LOCALE/$LOCALE/g" /etc/locale.gen
tmproot locale-gen
read -p "Password for root" PASSWDROOT && tmproot passwd <<< $PASSWDROOT
read -p "Please provide a username: " sudo_user && tmproot useradd -m -G wheel "$sudo_user"
read -p "Password for $sudo_user: " sudo_passwd && tmproot passwd "$sudo_user" <<< $sudo_passwd
tmproot grub-install "$IN_DEVICE"
tmproot grub-mkconfig -o /boot/grub/grub.cfg
tmproot mkinitcpio -P
tmproot systemctl enable tor.service
tmproot systemctl start NetworkManager.service
tmproot pacman -S git openssh networkmanager dhcpcd man-db man-pages pambase
tmproot pacman -S sudo bash-completion sshpass
tmproot sed -i 's/# %wheel/%wheel/g' /etc/sudoers
tmproot sed -i 's/%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
tmproot systemctl enable gdm.service