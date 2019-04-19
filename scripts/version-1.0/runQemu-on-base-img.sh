#!/bin/bash
numsmp="8"
memsize="6G"
imgloc=${HOME}/"runQemu"/"runQemu-imgs"
isoloc=${HOME}/"runQemu"/"runQemu-imgs"
imgfile="ub1604raw.img"
exeloc="/usr/local/bin"
CPU_LIST="0-7"
TASKSET="taskset -c ${CPU_LIST}"
#
sudo ${TASKSET} ${exeloc}/qemu-system-x86_64 -enable-kvm -cpu host -smp ${numsmp} \
     -m ${memsize} -L pc-bios -drive file=${imgloc}/${imgfile},format=raw \
     -boot c \
     -vnc :95 \
     -net nic -net user \
     -monitor tcp::9666,server,nowait \
     -localtime 
