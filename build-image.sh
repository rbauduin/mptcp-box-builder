#!/bin/bash


help() {
	echo "$(basename $0) [--no-debootstrap]"
	echo "--no-debootstrap : do not re-run debootstrap"
	echo "works with packer 0.7.5"
}

DO_DEBOOTSTRAP="YES"


set -eux
while [[ $# -gt 0 ]] ; do
	echo $*
	echo "^^"
	case $1 in
		--help)
			help
			exit
			;;
		--no-debootstrap)
			DO_DEBOOTSTRAP="NO"
			shift
			;;
		*)
			break
			;;
	esac
done






mkdir -p livework 
cd livework

[[ $DO_DEBOOTSTRAP == "YES" ]] && sudo debootstrap --arch=amd64 jessie chroot http://127.0.0.1:3142/ftp.be.debian.org/debian/

sudo mount none -t proc chroot/proc/
sudo mount none -t sysfs chroot/sys/
sudo mount none -t devpts chroot/dev/pts/



cat<<END_OF_SCRIPT >chroot/tmp/script1.sh
#!/bin/bash

set -eux
export HOME=/root
export PS1="\e[01;31m(live):\W \$ \e[00m"


echo "Acquire::http { Proxy \"http://localhost:3142\"; };"> /etc/apt/apt.conf.d/80-proxy

apt-get install -y --force-yes dialog dbus initramfs-tools aptitude
dbus-uuidgen > /var/lib/dbus/machine-id
wget -q -O - http://multipath-tcp.org/mptcp.gpg.key | apt-key add -
echo "deb http://multipath-tcp.org/repos/apt/debian jessie main" > /etc/apt/sources.list.d/mptcp.list

apt-get update
apt-get install -y --force-yes linux-mptcp iproute --no-install-recommends sudo openssh-server


mkinitramfs -o /boot/initrd-3.14.33.jessiemptcp 3.14.33.jessiemptcp
sed -i -e "s+127.0.0.1:3142/++" /etc/apt/sources.list
rm /etc/apt/apt.conf.d/80-proxy
apt-get update
apt-get clean
rm /var/lib/dbus/machine-id && rm -rf /tmp/*

echo "vagrant:vagrant::::/home/vagrant:/bin/bash" | newusers
cat <<! >/etc/sudoers.d/vagrant
vagrant    ALL=(ALL:ALL) NOPASSWD: ALL
!


cat <<! >> /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
!

echo mptcpbox > /etc/hostname
sed -i -e "s/[^-]localhost/ localhost mptcpbox/g" /etc/hosts
END_OF_SCRIPT

chmod +x chroot/tmp/script1.sh
LC_ALL=C sudo chroot chroot /tmp/script1.sh


sudo chroot chroot /etc/init.d/dbus stop
sudo umount chroot/proc chroot/sys chroot/dev/pts

qemu-img create -f raw image.raw 3G
sfdisk --force --unit S image.raw << EOF
63,5462037,L 
5462100,829356,S
EOF


sudo kpartx -av image.raw
p1=/dev/mapper/$(sudo kpartx -l image.raw |head -n 1 | awk '{print $1}')
p2=/dev/mapper/$(sudo kpartx -l image.raw |tail -n 1 | awk '{print $1}')


[[ -b $p1 ]] && [[ $p1 == *"loop"* ]] && mkfs.ext3 $p1
[[ -b $p2 ]] && [[ $p2 == *"loop"* ]] && mkswap $p2

sudo mkdir -p /mnt/vbox/p1

##p1=$(sudo losetup -f --show $base_p1)

sudo mount $p1 /mnt/vbox/p1

sudo rsync -aXH chroot/ /mnt/vbox/p1/

# umount/remount needed for grub to install correctly....
sudo umount /mnt/vbox/p1
sleep 1
sudo kpartx -d image.raw
# remount
sudo kpartx -av image.raw
p1=/dev/mapper/$(sudo kpartx -l image.raw |head -n 1 | awk '{print $1}')
p2=/dev/mapper/$(sudo kpartx -l image.raw |tail -n 1 | awk '{print $1}')
sudo mount $p1 /mnt/vbox/p1

# extract the root partition's uuid out of the chroot
# and use it to generate script2.sh
root_part=$(sudo blkid -s UUID -o value $p1)

cat <<END_OF_SCRIPT >/mnt/vbox/p1/tmp/script2.sh
#!/bin/bash

set -eux

export HOME=/root
export PS1="\e[01;31m(live):\W \$ \e[00m"

mount -t sysfs sysfs /sys
mount -t proc  proc  /proc

# avoid grub asking questions
cat << ! | debconf-set-selections -v
grub2   grub2/linux_cmdline                select   
grub2   grub2/linux_cmdline_default        select   
grub-pc grub-pc/install_devices_empty      boolean true
grub-pc grub-pc/install_devices            select  /dev/loop0 
!

apt-get install -y --force-yes grub2
cat > /boot/grub/device.map <<EOF
(hd0)   /dev/loop0
EOF

update-grub
sed -i -e "s+root=/dev/mapper/loop0p1+root=UUID=$root_part+g" /boot/grub/grub.cfg 
sed -i -e '/set root=(loop1)/d'  /boot/grub/grub.cfg
sed -i -e '/loopback loop1 \/mapper\/loop0p1/d'  /boot/grub/grub.cfg
sed -i -e "/loop1/d" /boot/grub/grub.cfg

grub-install /dev/loop0

echo "UUID=$root_part / ext3 defaults 0 1" > /etc/fstab

umount /proc /sys
END_OF_SCRIPT
chmod +x /mnt/vbox/p1/tmp/script2.sh

sudo mount --bind /dev /mnt/vbox/p1/dev
LC_ALL=C sudo chroot /mnt/vbox/p1/ /tmp/script2.sh
sudo umount /mnt/vbox/p1/dev
sleep 1

sudo umount /mnt/vbox/p1
sleep 1
sudo kpartx -d image.raw


#sudo qemu-system-x86_64 -hda image.raw

qemu-img convert -f raw -O vdi image.raw image.vdi



VBoxManage createvm --name "boxcreation" --register
VBoxManage modifyvm "boxcreation" --memory 512 --acpi on --boot1 dvd
VBoxManage modifyvm "boxcreation" --nic1 nat # --bridgeadapter1 eth0
#VBoxManage modifyvm "boxcreation" --macaddress1 XXXXXXXXXXXX
VBoxManage modifyvm "boxcreation" --ostype Debian_64
VBoxManage storagectl "boxcreation" --name "IDE Controller" --add ide
VBoxManage storageattach "boxcreation" --storagectl "IDE Controller"  \
    --port 0 --device 0 --type hdd --medium image.vdi

#VBoxManage storageattach "boxcreation" --storagectl "IDE Controller" \
#    --port 1 --device 0 --type dvddrive --medium /home/rb/Downloads/grml64-full_2014.11.iso

# uncomment to start it with virtualbox:
#VBoxManage startvm boxcreation


rm -f image.ovf image-disk1.vmdk

VBoxManage export "boxcreation" --ovf10 --output image.ovf
tar cf image.ova image.ovf image-disk1.vmdk



# destroy vm:
VBoxManage storageattach "boxcreation" --storagectl "IDE Controller"  \
    --port 0 --device 0 --type hdd --medium none
VBoxManage storageattach "boxcreation" --storagectl "IDE Controller" \
    --port 1 --device 0 --type dvddrive --medium emptydrive

VBoxManage -q storagectl boxcreation --name "IDE Controller" --remove
VBoxManage -q closemedium disk image.vdi
VBoxManage -q unregistervm boxcreation  --delete


