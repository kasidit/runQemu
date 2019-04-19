#!/bin/bash
numsmp="2"
memsize="2G"
imgloc=${HOME}/images
isoloc=${HOME}/images
imgfile="ubuntu1604qcow2.img"
exeloc="/usr/bin"
#
sudo ${exeloc}/qemu-system-x86_64 \
     -enable-kvm \
     -cpu host -smp ${numsmp} \
     -m ${memsize} -drive file=${imgloc}/${imgfile},format=qcow2 \
     -boot d -cdrom ${isoloc}/ubuntu-16.04.6-server-amd64.iso \
     -vnc :95 \
     -net nic -net user \
     -localtime
