#!/usr/bin/env bash
## Preferences can be set up to about line 150
# VERIFY BOOT MODE
set -e 


efi_boot_mode(){
    [[ -d /sys/firmware/efi/efivars ]] && return 0
    return 1
}
install_x(){ return 0; }     # return 0 if you want to install X
use_lvm(){ return 0; }       # return 0 if you want lvm
use_crypt(){ return 0; }     # return 0 if you want crypt
use_bcm4360() { return 1; }  # return 0 if you want bcm4360
use_nonus_keymap(){ return 1; } # return 0 if using non-US keyboard keymap (default)
default_keymap='us'             # set to your keymap name
$(use_nonus_keymap()) && loadkeys "${default_keymap}"
HOSTNAME="ELEACHE"
# VIDEO_DRIVER="xf86-video-vmware"
IN_DEVICE=/dev/sda
#IN_DEVICE=/dev/nvme0n0
# If IN_DEV is nvme then slices are p1, p2 etc
if  $(efi_boot_mode) ; then
    DISKLABEL='GPT'
    EFI_MTPT=/mnt/boot/efi
    if [[ $IN_DEVICE =~ nvme ]]; then
        EFI_DEVICE="${IN_DEVICE}p1"   # NOT for MBR systems
        ROOT_DEVICE="${IN_DEVICE}p2"  # only for non-LVM
        SWAP_DEVICE="${IN_DEVICE}p3"  # only for non-LVM 
        HOME_DEVICE="${IN_DEVICE}p4"  # only for non-LVM
    else
        EFI_DEVICE="${IN_DEVICE}1"   # NOT for MBR systems
        ROOT_DEVICE="${IN_DEVICE}2"  # only for non-LVM
        SWAP_DEVICE="${IN_DEVICE}3"  # only for non-LVM 
        HOME_DEVICE="${IN_DEVICE}4"  # only for non-LVM
    fi
else
    # Any mobo with nvme probably is gonna be EFI Im thinkin...
    # Probably no non-UEFI mobos with nvme drives
    DISKLABEL='DOS'
    unset EFI_DEVICE
    BOOT_DEVICE="${IN_DEVICE}1"
    BOOT_MTPT=/mnt/boot
    ROOT_DEVICE="${IN_DEVICE}2"
    SWAP_DEVICE="${IN_DEVICE}3"  # only for non-LVM 
    HOME_DEVICE="${IN_DEVICE}4"  # only for non-LVM
fi

if $(use_lvm) ; then
    # VOLUME GROUPS  (Probably should unset SWAP_DEVICE and HOME_DEVICE)
    PV_DEVICE="$ROOT_DEVICE"
    VOL_GROUP="arch_vg"
    LV_ROOT="ArchRoot"
    LV_HOME="ArchHome"
    LV_SWAP="ArchSwap"
fi
if $(efi_boot_mode) ; then
    EFI_SIZE=512M
    unset BOOT_SIZE
else
    unset EFI_SIZE; unset EFI_MTPT
    BOOT_SIZE=512M
fi

# CONFIGURATION
SWAP_SIZE=16G
ROOT_SIZE=80G
HOME_SIZE=100G
TIME_ZONE="$(wget -qO - http://geoip.ubuntu.com/lookup | sed -n -e 's/.*<TimeZone>\(.*\)<\/TimeZone>.*/\1/p')"
TIME_ZONE=${TIME_ZONE:="America/Monterrey"}
LOCALE="en_US.UTF-8"
FILESYSTEM=ext4
DESKTOP=('cinnamon' 'nemo-fileroller' 'lightdm-gtk-greeter')
declare -A DISPLAY_MGR=( [dm]='lightdm' [service]='lightdm.service' )
if $(use_bcm4360) ; then
    WIRELESSDRIVERS="broadcom-wl-dkms"
else
    WIRELESSDRIVERS=""
fi
BASE_SYSTEM=(linux linux-firmware nano grub networkmanager dhcpcd netctl wpa_supplicant dialog)
BASIC_X=(xorg-server xorg-xinit gdm i3 tilix)
EXTRA_X1=(birdfont gnu-free-fonts haskell-sdl2-ttf IEC lib32-sdl2_ttf lib32-sdl_ttf mftrace noto-fonts noto-fonts-extra opendesktop-fonts OTF perl-font-ttf python-ziafont sdl2_ttf sdl_ttf terminus-font-ttf ttf-anonymous-pro ttf-arphic-ukai ttf-arphic-uming ttf-baekmuk ttf-bitstream-vera ttf-caladea ttf-carlito ttf-cascadia-code ttf-cormorant ttf-crimson ttf-crimson-pro ttf-crimson-pro-variable ttf-croscore ttf-dejavu ttf-droid ttf-eurof ttf-fantasque-sans-mono ttf-fira-code ttf-fira-mono ttf-fira-sans ttf-font-awesome ttf-hack ttf-hanazono ttf-hannom ttf-ibm-plex ttf-inconsolata ttf-indic-otf ttf-input ttf-ionicons ttf-iosevka-nerd ttf-jetbrains-mono ttf-joypixels ttf-junicode ttf-khmer ttf-lato ttf-liberation ttf-linux-libertine ttf-linux-libertine-g ttf-monofur ttf-monoid ttf-nerd-fonts-symbols-1000-em ttf-nerd-fonts-symbols-1000-em-mono ttf-nerd-fonts-symbols-2048-em ttf-nerd-fonts-symbols-2048-em-mono ttf-opensans ttf-overpass ttf-proggy-clean ttf-roboto ttf-roboto-mono ttf-sarasa-gothic ttf-sazanami ttf-tibetan-machine ttf-ubuntu-font-family)
# EXTRA_X2=(  )
# EXTRA_X3=(  )
EXTRA_DESKTOPS=( i3-gaps i3status i3blocks feh terminator ttf-font-awesome ttf-ionicons )
# GOODIES=( htop neofetch screenfetch powerline powerline-fonts powerline-vim )
qtile_desktop=( "${multimedia_stuff[@]}" )
# xmonad_desktop=( xmonad xmonad-contrib )
# awesome_desktop=( awesome vicious )
# kde_desktop=( plasma plasma-wayland-session kde-applications )
devel_stuff=( git nodejs npm npm-check-updates ruby )
multimedia_stuff=( imagemagick cmus mpg123 alsa-utils )
all_pkgs=( BASE_SYSTEM BASIC_X EXTRA_DESKTOPS qtile_desktop devel_stuff )
error(){ echo "Error: $1" && exit 1; }
show_prefs(){
    echo "Here are your preferences that will be installed: "
    echo -e "\n\n"
    echo "HOSTNAME: ${HOSTNAME}  INSTALLATION DRIVE: ${IN_DEVICE}  DISKLABEL: ${DISKLABEL}"
    echo "TIMEZONE: ${TIME_ZONE}   LOCALE:  ${LOCALE}"
    echo "KEYBOARD: ${default_keymap}"
    if $(use_crypt); then echo "We ARE using CRYPTSETUP." 
    else echo "We ARE NOT using CRYPTSETUP."
    fi

    if $(efi_boot_mode); then
        if $(use_lvm); then
            echo "We ARE using LVM"
            echo "PHYS_VOL is ${PV_DEVICE} with LVGRP ${VOL_GROUP}"
            echo "ROOT_SIZE: ${ROOT_SIZE} on ${VOL_GROUP}-${LV_ROOT}"
            echo "EFI_SIZE: ${EFI_SIZE} on ${EFI_DEVICE}"
            echo "SWAP_SIZE: ${SWAP_SIZE} on ${VOL_GROUP}-${LV_SWAP}"
            echo "HOME_SIZE: Occupying rest of ${VOL_GROUP}-${LV_HOME}"
        else
            echo "We ARE NOT using LVM"
            echo "ROOT_SIZE: ${ROOT_SIZE} on ${ROOT_DEVICE}"
            echo "EFI_SIZE: ${EFI_SIZE} on ${EFI_DEVICE}"
            echo "SWAP_SIZE: ${SWAP_SIZE} on ${SWAP_DEVICE}"
            echo "HOME_SIZE: Occupying rest of ${HOME_DEVICE}"
        fi
    else
        if $(use_lvm); then
            echo "We ARE using LVM"
            echo "PV is ${PV_DEVICE} with LVGRP ${VOL_GROUP}"
            echo "ROOT_SIZE: ${ROOT_SIZE} on ${VOL_GROUP}-${LV_ROOT}"
            echo "EFI_SIZE: ${EFI_SIZE} on ${EFI_DEVICE}"
            echo "SWAP_SIZE: ${SWAP_SIZE} on ${VOL_GROUP}-${LV_SWAP}"
            echo "HOME_SIZE: Occupying rest of ${VOL_GROUP}-${LV_HOME}"
        else
            echo "We ARE NOT using LVM"
            echo "ROOT_SIZE: ${ROOT_SIZE} on ${ROOT_DEVICE}"
            echo "BOOT_SIZE: ${BOOT_SIZE} on ${BOOT_DEVICE}"
            echo "SWAP_SIZE: ${SWAP_SIZE} on ${SWAP_DEVICE}"
            echo "HOME_SIZE: Occupying rest of ${HOME_DEVICE}"
        fi
    fi

    if $(install_x); then 
        echo "We ARE installing X with driver: ${VIDEO_DRIVER}"
        echo "We are using ${DISPLAY_MGR[dm]} with ${DESKTOP[@]}"
        card=$(lspci | grep VGA | sed 's/^.*: //g')
        echo "You're using a $card" && echo
    else
        echo "We ARE NOT installing X "
    fi

    echo "Type any key to continue or CTRL-C to exit..."
    read empty
}

# FIND GRAPHICS CARD
find_card(){
    card=$(lspci | grep VGA | sed 's/^.*: //g')
    echo "You're using a $card" && echo
}

# VALIDATE PKG NAMES IN SCRIPT
validate_pkgs(){
    echo "updating pacman pkg database."
    pacman -Sy     # need to initialize pacman db
    echo && echo -n "    validating pkg names..."
    for pkg_arr in "${all_pkgs[@]}"; do
        declare -n arr_name=$pkg_arr
        for pkg_name in "${arr_name[@]}"; do
            if $( pacman -Sp $pkg_name &>/dev/null ); then
                echo -n .
            else 
                echo -n "$pkg_name from $pkg_arr not in repos."
            fi
        done
    done
    echo -e "\n" && read -p "Press any key to continue or Ctl-C to check for problem." empty
}

# ENCRYPT DISK WHEN POWER IS OFF
crypt_setup(){
    # Takes a disk partition as an argument
    # Give msg to user about purpose of encrypted physical volume
    cat <<END_OF_MSG

"You are about to encrypt a physical volume.  Your data will be stored in an encrypted
state when powered off.  Your files will only be protected while the system is powered off.
This could be very useful if your laptop gets stolen, for example."

END_OF_MSG
    read -p "Encrypting a disk partition. Please enter a memorable passphrase: " -s passphrase
    #echo -n "$passphrase" | cryptsetup -q luksFormat $1 -
    echo -n "$passphrase" | cryptsetup -q luksFormat --hash=sha512 --key-size=512 --cipher=aes-xts-plain64 --verify-passphrase $1 -

    cryptsetup luksOpen  $1 sda_crypt
    echo "Wiping every byte of device with zeros, could take a while..."
    dd if=/dev/zero of=/dev/mapper/sda_crypt bs=1M
    cryptsetup luksClose sda_crypt
    echo "Filling header of device with random data..."
    dd if=/dev/urandom of="$1" bs=512 count=20480
}

format_it(){
    device=$1; fstype=$2
    mkfs."$fstype" "$device" || error "format_it(): Can't format device $device with $fstype"
}

mount_it(){
    device=$1; mt_pt=$2
    mount "$device" "$mt_pt" || error "mount_it(): Can't mount $device to $mt_pt"
}

non_lvm_create(){
    # We're just doing partitions, no LVM here
    clear
    if $(efi_boot_mode); then
        sgdisk -Z "$IN_DEVICE"
        sgdisk -n 1::+"$EFI_SIZE" -t 1:ef00 -c 1:EFI "$IN_DEVICE"
        sgdisk -n 2::+"$ROOT_SIZE" -t 2:8300 -c 2:ROOT "$IN_DEVICE"
        sgdisk -n 3::+"$SWAP_SIZE" -t 3:8200 -c 3:SWAP "$IN_DEVICE"
        sgdisk -n 4 -c 4:HOME "$IN_DEVICE"
       
        # Format and mount slices for EFI
        format_it "$ROOT_DEVICE" "$FILESYSTEM"
        mount_it "$ROOT_DEVICE" /mnt
        mkfs.fat -F32 "$EFI_DEVICE"
        mkdir /mnt/boot && mkdir /mnt/boot/efi
        mount_it "$EFI_DEVICE" "$EFI_MTPT"
        format_it "$HOME_DEVICE" "$FILESYSTEM"
        mkdir /mnt/home
        mount_it "$HOME_DEVICE" /mnt/home
        mkswap "$SWAP_DEVICE" && swapon "$SWAP_DEVICE"
    else
        # For non-EFI. Eg. for MBR systems 
cat > /tmp/sfdisk.cmd << EOF
$BOOT_DEVICE : start= 2048, size=+$BOOT_SIZE, type=83, bootable
$ROOT_DEVICE : size=+$ROOT_SIZE, type=83
$SWAP_DEVICE : size=+$SWAP_SIZE, type=82
$HOME_DEVICE : type=83
EOF


        # Using sfdisk because we're talking MBR disktable now...
        sfdisk "$IN_DEVICE" < /tmp/sfdisk.cmd 

        # Format and mount slices for non-EFI
        format_it "$ROOT_DEVICE" "$FILESYSTEM"
        mount_it "$ROOT_DEVICE" /mnt
        format_it "$BOOT_DEVICE" "$FILESYSTEM"
        mkdir /mnt/boot
        mount_it "$BOOT_DEVICE" "$BOOT_MTPT"
        format_it "$HOME_DEVICE" "$FILESYSTEM"
        mkdir /mnt/home
        mount_it "$HOME_DEVICE" /mnt/home
        mkswap "$SWAP_DEVICE" && swapon "$SWAP_DEVICE"
    fi

    lsblk "$IN_DEVICE"
    echo "Type any key to continue..."; read empty
}

# PART OF LVM INSTALLATION
lvm_hooks(){
    clear
    echo "adding lvm2 to mkinitcpio hooks HOOKS=( base udev ... block lvm2 filesystems )"
    sleep 4
    sed -i 's/^HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)$/HOOKS=(base udev autodetect modconf block lvm2 filesystems keyboard fsck)/g' /mnt/etc/mkinitcpio.conf
    arch-chroot /mnt mkinitcpio -P
    echo "Press any key to continue..."; read empty
}

# ONLY FOR LVM INSTALLATION
lvm_create(){
    clear
    sgdisk -Z "$IN_DEVICE"
    if $(efi_boot_mode); then
        sgdisk -n 1::+"$EFI_SIZE" -t 1:ef00 -c 1:EFI "$IN_DEVICE"
        sgdisk -n 2 -t 2:8e00 -c 2:VOLGROUP "$IN_DEVICE"
        # Format
        mkfs.fat -F32 "$EFI_DEVICE"
    else
        #  # Create the slice for the Volume Group as first and only slice

cat > /tmp/sfdisk.cmd << EOF
$BOOT_DEVICE : start= 2048, size=+$BOOT_SIZE, type=83, bootable
$ROOT_DEVICE : type=83
EOF
        # Using sfdisk because we're talking MBR disktable now...
        sfdisk "$IN_DEVICE" < /tmp/sfdisk.cmd 
    fi


    # run cryptsetup on root device
    $(use_crypt) && crypt_setup "$ROOT_DEVICE"
    
    # create the physical volumes
    pvcreate "$PV_DEVICE"
    # create the volume group
    vgcreate "$VOL_GROUP" "$PV_DEVICE" 
    
    # You can extend with 'vgextend' to other devices too

    # create the volumes with specific size
    lvcreate -L "$ROOT_SIZE" "$VOL_GROUP" -n "$LV_ROOT"
    lvcreate -L "$SWAP_SIZE" "$VOL_GROUP" -n "$LV_SWAP"
    lvcreate -l 100%FREE  "$VOL_GROUP" -n "$LV_HOME"
    
    # Format SWAP 
    mkswap /dev/"$VOL_GROUP"/"$LV_SWAP"
    swapon /dev/"$VOL_GROUP"/"$LV_SWAP"

    # insert the vol group module
    modprobe dm_mod
    # activate the vol group
    vgchange -ay
    
    # Format either the EFI_DEVICE or the BOOT_DEVICE
    if $(efi_boot_mode) ; then
        mkfs.fat -F32 "$EFI_DEVICE"
    else
        format_it "$BOOT_DEVICE" "$FILESYSTEM"
    fi

    # Format the VG members
    format_it /dev/"$VOL_GROUP"/"$LV_ROOT" "$FILESYSTEM"
    format_it /dev/"$VOL_GROUP"/"$LV_HOME" "$FILESYSTEM"

    # mount the volumes
    mount_it /dev/"$VOL_GROUP"/"$LV_ROOT" /mnt
    mkdir /mnt/home
    mount_it /dev/"$VOL_GROUP"/"$LV_HOME" /mnt/home

    # Mount either the EFI or BOOT partition
    if $(efi_boot_mode) ; then
        mkdir /mnt/boot && mkdir /mnt/boot/efi
        mount_it "$EFI_DEVICE" "$EFI_MTPT"
    else
        mkdir /mnt/boot
        mount_it "$BOOT_DEVICE" /mnt/boot
    fi

    lsblk
    echo "LVs created and mounted. Press any key."; read empty;
}


##########################################
##        SCRIPT STARTS HERE
##########################################

###  WELCOME
clear
echo -e "\n\n\nWelcome to the Fast ARCH Installer!"
sleep 4
clear && count=5
while true; do
    [[ "$count" -lt 1 ]] && break
    echo -e  "\e[1A\e[K Launching install in $count seconds"
    count=$(( count - 1 ))
    sleep 1
done

##  check if reflector update is done...
clear
echo -e "\n\nWaiting until reflector has finished updating mirrorlist..."
while true; do
    pgrep -x reflector &>/dev/null || break
    echo -n '.'
    sleep 2
done

## CHECK CONNECTION TO INTERNET
clear
echo -e "\n\nTesting internet connection..."
$(ping -c 3 archlinux.org &>/dev/null) || (echo "Not Connected to Network!!!" && exit 1)
echo "Good!  We're connected!!!" && sleep 3

## SHOW THE PREFERENCES BEFORE STARTING INSTALLATION
## Last chance for user to doublecheck his preferences
show_prefs

# MAKE SURE CURRENT PKG NAMES ARE CORRECT
validate_pkgs

## CHECK TIME AND DATE BEFORE INSTALLATION
timedatectl set-ntp true
echo && echo -e "\n\nDate/Time service Status is . . . "
timedatectl status
sleep 4

### PARTITION AND FORMAT AND MOUNT
clear
echo -e "\n\nPartitioning Hard Drive!! Press any key to continue..." ; read empty
if $(use_lvm) ; then
    lvm_create
else
    non_lvm_create
fi


## INSTALL BASE SYSTEM
clear
echo && echo -e "\n\nPress any key to continue to install BASE SYSTEM..."; read empty
pacstrap /mnt "${BASE_SYSTEM[@]}"
echo && echo -e "\n\nBase system installed.  Press any key to continue..."; read empty

## UPDATE mkinitrd HOOKS if using LVM
$(use_lvm) && arch-chroot /mnt pacman -S lvm2
$(use_lvm) && lvm_hooks

# GENERATE FSTAB
echo -e "\n\nGenerating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# EDIT FSTAB IF NECESSARY
clear
echo && echo -e "\n\nHere's the new /etc/fstab...\n\n"; cat /mnt/etc/fstab
echo && echo -e "\n\nPress any key to continue"; read edit_fstab


## SET UP TIMEZONE AND LOCALE
clear
echo && echo -e "\n\nsetting timezone to $TIME_ZONE..."
arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$TIME_ZONE" /etc/localtime
arch-chroot /mnt hwclock --systohc --utc
arch-chroot /mnt date
echo && echo -e "\n\nHere's the date info, hit any key to continue..."; read td_yn

## SET UP LOCALE
clear
echo && echo -e "\nsetting locale to $LOCALE ..."
arch-chroot /mnt sed -i "s/#$LOCALE/$LOCALE/g" /etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=$LOCALE" > /mnt/etc/locale.conf
export LANG="$LOCALE"
cat /mnt/etc/locale.conf
echo && echo -e "\n\nHere's your /mnt/etc/locale.conf. Type any key to continue."; read empty


## HOSTNAME
clear
echo && echo -e "\n\nSetting hostname..."; sleep 3
echo "$HOSTNAME" > /mnt/etc/hostname

cat > /mnt/etc/hosts <<HOSTS
127.0.0.1      localhost
::1            localhost
127.0.1.1      $HOSTNAME.localdomain     $HOSTNAME
HOSTS

echo && echo -e "\n\n/etc/hostname and /etc/hosts files configured..."
echo -e "/etc/hostname . . . \n"
cat /mnt/etc/hostname 
echo -e "\n/etc/hosts . . .\n"
cat /mnt/etc/hosts
echo && echo -e "\n\nHere are /etc/hostname and /etc/hosts. Type any key to continue "; read empty

## SET PASSWD
clear
echo "Setting ROOT password..."
arch-chroot /mnt passwd

## INSTALLING MORE ESSENTIALS
clear
echo && echo -e "\n\nEnabling dhcpcd, pambase, sshd and NetworkManager services..." && echo
arch-chroot /mnt pacman -S git openssh networkmanager dhcpcd man-db man-pages pambase
arch-chroot /mnt systemctl enable dhcpcd.service
arch-chroot /mnt systemctl enable sshd.service
arch-chroot /mnt systemctl enable NetworkManager.service
arch-chroot /mnt systemctl enable systemd-homed

echo && echo -e "\n\nPress any key to continue..."; read empty

## ADD USER ACCT
clear
echo && echo -e "\n\nAdding sudo + user acct..."
sleep 2
arch-chroot /mnt pacman -S sudo bash-completion sshpass
arch-chroot /mnt sed -i 's/# %wheel/%wheel/g' /etc/sudoers
arch-chroot /mnt sed -i 's/%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
echo && echo -e "\n\nPlease provide a username: "; read sudo_user
echo && echo -e "\n\nCreating $sudo_user and adding $sudo_user to sudoers..."
arch-chroot /mnt useradd -m -G wheel "$sudo_user"
echo && echo -e "\n\nPassword for $sudo_user?"
arch-chroot /mnt passwd "$sudo_user"

## INSTALL WIFI
$(use_bcm4360) && arch-chroot /mnt pacman -S "$WIRELESSDRIVERS"
[[ "$?" -eq 0 ]] && echo -e "\n\nWifi Driver successfully installed!"; sleep 5

## INSTALL X AND DESKTOP  
if $(install_x); then
    clear && echo -e "\n\nInstalling X and X Extras and Video Driver. Type any key to continue"; read empty
    arch-chroot /mnt pacman -S "${BASIC_X[@]}"
    arch-chroot /mnt pacman -S "${EXTRA_X1[@]}"
    arch-chroot /mnt pacman -S "${EXTRA_X2[@]}"
    arch-chroot /mnt pacman -S "${EXTRA_X3[@]}"
    arch-chroot /mnt pacman -S "${multimedia_stuff[@]}"
    arch-chroot /mnt pacman -S "${printing_stuff[@]}"
    arch-chroot /mnt pacman -S "${devel_stuff[@]}"
    your_card=$(find_card)
    echo -e "\n\n${your_card} and you're installing the $VIDEO_DRIVER driver... (Type key to continue) "; read blah
    arch-chroot /mnt pacman -S "$VIDEO_DRIVER"
    arch-chroot /mnt pacman -S "${EXTRA_DESKTOPS[@]}"
    arch-chroot /mnt pacman -S "${GOODIES[@]}"

    echo -e "\n\nEnabling display manager service..."
    arch-chroot /mnt systemctl enable ${DISPLAY_MGR[service]}
    echo && echo -e "\n\nYour desktop and display manager should now be installed..."
    sleep 5
fi

## INSTALL GRUB
clear
echo -e "\n\nInstalling grub..." && sleep 4
arch-chroot /mnt pacman -S grub os-prober

if $(efi_boot_mode) ; then
    arch-chroot /mnt pacman -S efibootmgr
    
    [[ ! -d /mnt/boot/efi ]] && error "Grub Install: no /mnt/boot/efi directory!!!" 
    arch-chroot /mnt grub-install "$IN_DEVICE" --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi

    ## This next bit is for Ryzen systems with weird BIOS/EFI issues; --no-nvram and --removable might help
    [[ $? != 0 ]] && arch-chroot /mnt grub-install \
       "$IN_DEVICE" --target=x86_64-efi --bootloader-id=GRUB \
       --efi-directory=/boot/efi --no-nvram --removable
    echo -e "\n\nefi grub bootloader installed..."
else
    arch-chroot /mnt grub-install "$IN_DEVICE"
    echo -e "\n\nmbr bootloader installed..."
fi
echo -e "\n\nconfiguring /boot/grub/grub.cfg..."
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    

echo -e "\n\nSystem should now be installed and ready to boot!!!"
echo && echo -e "\nType shutdown -h now and remove Installation Media and then reboot"
echo && echo



'