#!/bin/bash
numsmp="4"
memsize="6G"
imgloc=${HOME}/"runQemu"/"runQemu-imgs"
isoloc=${HOME}/"runQemu"/"runQemu-imgs"
imgfile="ubuntu1604raw.img"
exeloc="/usr/local/bin"
CPU_LIST="0-11"
TASKSET="taskset -c ${CPU_LIST}"
#
sudo ${TASKSET} ${exeloc}/qemu-system-x86_64 -enable-kvm -cpu host -smp ${numsmp} \
     -m ${memsize} -drive file=${imgloc}/${imgfile},format=raw \
     -boot d -cdrom ${isoloc}/ubuntu-16.04.3-server-amd64.iso \
     -vnc :95 \
     -net nic -net user \
     -monitor tcp::9666,server,nowait \
     -localtime 
