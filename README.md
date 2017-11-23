<h1>Tutorial: การใช้ qemu-kvm สร้าง virtual machines บน ubuntu 16.04 server</h1>
<ul>
 <li> <a href="#part1">1. กำหนดให้ ubuntu 16.04 host สนับสนุนการทำงานแบบ nested virtualization</a>
 <li> <a href="#part2">2. สร้าง virtual hard disk ด้วย qemu-img</a> 
      <ul>
       <li> <a href="#part2-1">2.1 disk format แบบ raw</a>
       <li> <a href="#part2-2">2.2 disk format แบบ qcow2</a>
      </ul>
<li> <a href="#part3">3 การติดตั้ง Guest OS แบบ ubuntu 16.04 บน virtual disks</a> 
      <ul>
       <li> <a href="#part3-1">3.1 ติดตั้ง guest OS แบบใช้ btrfs file system บน raw disk</a>
       <li> <a href="#part3-2">3.2 สร้าง disk แบบ qcow2 overlay</a>
      </ul>
</ul>
<p><p>
ใน Tutorial นี้เราสมมุติว่า นศ มีเครื่องจริงหรือ host computer (หรือ server) ที่ติดตั้ง ubuntu 16.04 และ นศ ต้องการจะติดตั้งและใช้ kvm เพื่อสร้าง virtual machine (vm) ที่มี Guest OS เป็น ubuntu 16.04 เช่นกัน Guide line ในการอ่าน tutorial นี้มีดังนี้ 
<ul>
<li>ในกรณีที่ นศ ต้องการให้ vm ที่ นศ สร้างขึ้นสามารถรัน kvm ได้อีกชั้นหนึ่ง ขอให้ นศ อ่านวิธีการกำหนดค่าบนเครื่อง host ในส่วนที่ 1 มิเช่นนั้น ถ้า นศ ไม่ได้ต้องการ feature ดังกล่าวก็ข้ามไปดูส่วนที่ 2 ได้เลย  
<li>ในส่วนที่ 3 นศ ต้องเลือกว่าจะติดตั้ง guest OS บน vm โดยใช้ ext4 หรือ btrfs
</ul>
<p><p>
<a id="part1"><h2>1. กำหนดให้ ubuntu 16.04 host สนับสนุนการทำงานแบบ nested virtualization</h2></a>
<p><p>
ก่อนอื่นเรา assume ว่าเครื่อง host server ของ นศ มี hardware virtualization support สำหรับ kvm นศ สามารถเช็คได้ด้วยคำสั่ง 
<pre>
$ sudo su
# egrep --color="auto" "vmx|svm" /proc/cpuinfo
... vmx ... (เครื่อง intel cpu)
#
</pre>
<p><p>
เมื่อ นศ ต้องการรัน VM ภายใน VM อีกชั้นหนึ่ง นศ จะต้องกำหนดค่าดังต่อไปนี้
<p><p>
<pre>
$ sudo su
# cat /sys/module/kvm_intel/parameters/nested 
N
# echo 'options kvm_intel nested=1' >> /etc/modprobe.d/qemu-system-x86.conf 
#
</pre>
หลังจากนั้นให้ reboot เครื่อง host 
<p><p>
ให้ login เข้าเครื่อง host อีกครั้งหนึ่งและเช็คว่าไฟล์ /sys/module/kvm_intel/parameters/nested มีค่า Y หรือไม่
<p><p>
<pre>
$ sudo su
# cat /sys/module/kvm_intel/parameters/nested
Y
#
</pre>
<p><p>
หลังจากนั้น เมื่อ นศ รัน kvm ด้วยคำสั่ง qemu-system-x86_64 จาก command line (เรา assume ว่ามี qemu-kvm software ติดตั้งอยู่บน host แล้ว) ให้กำหนด option "-cpu host" เครื่อง VM ที่ นศ รันด้วย option นี้ก็จะสามารถรัน kvm ได้อีกชั้นหนึ่ง สมมุติว่า นศ รัน qemu-kvm ด้วยคำสั่ง
<pre>
$ sudo qemu-system-x86_64 ... -cpu host ...
</pre>
เมื่อ นศ login เข้าสู่เครื่อง VM นั้น สมมุติว่าเป็น ubuntu เหมือนกัน นศ สามารถตรวจสอบได้ว่า cpu ของเครื่อง VM ของ นศ มี hardware virtualization support หรือไม่ด้วยคำสั่ง
<p><p>
<pre>
# egrep --color="auto" "vmx|svm" /proc/cpuinfo
</pre>
<p><p>
ซึ่งควรจะเห็น บรรทัดที่มีคำว่า vmx หรือ svm
<p><p>
 <a id="part2"><h2>2. สร้าง virtual hard disk ด้วย qemu-img</h2></a>
<p><p>
<table>
<tr><td>
<b>สำหรับวิชา คพ. 449:</b> นศ แต่ละคนจะสร้าง virtual disk แบบ raw ขนาด 4G เพื่อประหยัดพื้นที่ disk บน host server  
</td></tr>
</table>
<p><p>
  <a id="part2-1"><h3>2.1 disk format แบบ raw</h3></a>
<p><p>
เราจะทดลองสร้าง disk image แบบต่างๆ แต่ก่อนอื่นเราต้องสร้าง disk เพื่อติดตั้ง guest OS ของ VM ในคำสั่งถัดไป นศ จะสร้าง disk image แบบ raw 
<p><p>
disk แบบ raw นี้ มีค่าใช้จ่ายคือมันจะใช้พื้นที่บน disk จริงเท่ากับปริมาณที่ นศ ขอไม่ว่า นศ จะใช้พื้นที่เก็บข้อมูลจริงเท่าไร แต่มีข้อดีอ่านเขียนข้อมูลได้เร็ว
<p><p>
<pre>
$ cd $HOME
$ mkdir runQemu
$ cd runQemu
$ mkdir runQemu-img 
$ cd runQemu-img
$ wget http://releases.ubuntu.com/16.04/ubuntu-16.04.3-server-amd64.iso
$ ls
$ <b>qemu-img create -f raw ubuntu1604raw.img 4G</b>
Formatting 'ubuntu1604raw.img', fmt=raw size=4294967296
$ ls -l
total 844804
-rw-rw-r-- 1 kasidit kasidit   865075200 Sep 20 15:55 ubuntu-16.04.3-server-amd64.iso
<b>-rw-r--r-- 1 kasidit kasidit 4294967296 Nov 16 15:38 ubuntu1604raw.img</b>
$
</pre>
<p><p>
  <a id="part2-2"><h3>2.2 disk format แบบ qcow2</h3></a>
ถ้าผมสร้าง image แบบ qemu's copy on write (qcow2) ซึ่ง qemu-kvm จะเขียนข้อมูลลงสู่ disk จริงก็ต่อเมือมีการเพิ่มข้อมูลหรือ modify ข้อมูลเท่านั้น นศ จะเห็นว่าขนาดของ qcow2 disk เริ่มต้นจะไม่ใหญ่มากแต่จะขยายมากขึ้นเมื่อมีการเขียนข้อมูลสู่ disk จริง ข้อดีของ disk แบบ raw คือ performance 
ในขณะที่ข้อดีของแบบ qcow2 คือใช้พื้นที่เท่าที่ใช้จริง
<p><p>
<pre>
$ <b>qemu-img create -f qcow2 ubuntu1604qcow2.img 16G</b>
Formatting 'ubuntu1604qcow2.img', fmt=qcow2 size=17179869184 encryption=off cluster_size=65536 lazy_refcounts=off refcount_bits=16
$ ls -l
total 845000
-rw-rw-r-- 1 kasidit kasidit   865075200 Sep 20 15:55 ubuntu-16.04.3-server-amd64.iso
<b>-rw-r--r-- 1 kasidit kasidit      196864 Nov 16 15:49 ubuntu1604qcow2.img</b>
-rw-r--r-- 1 kasidit kasidit  4294967296 Nov 16 15:38 ubuntu1604raw.img
$
</pre>
disk แบบ qcow2 มี features ที่เราจะกล่าวถึงอีกประการคือแบบการสร้าง virtual disk แบบ qcow2 overlay ซึ่งผมจะอธิบายอีกทีหลังจากส่วนที่ 3 
<p><p>
  <a id="part3"><h2>3 การติดตั้ง Guest OS แบบ ubuntu 16.04 บน virtual disks</h3></a>
<p><p>
ในส่วนนี้ นศ จะเรียก kvm จาก command line เพื่อสร้าง Guest OS บน disk image เปล่าๆ ที่สร้างขึ้น เพื่อความสะดวกผมเขียนคำสั่งลงใน bash shell script 
<table>
<tr><td>
<b>สำหรับวิชา คพ. 449:</b> ขอให้ นศ เปลี่ยน -vnc :NN  และ -monitor tcp:NNNN ให้ NN และ NNNN เป็นเลขเฉพาะของแต่ละคน
</td></tr>
</table>
<pre>
$ cd $HOME/runQemu
$ mkdir runQemu-scripts
$ cd runQemu-scripts
$ vi <a href="https://github.com/kasidit/runQemu/blob/master/runQemu-scripts/runQemu-on-base-img-cdrom.sh">runQemu-on-base-img-cdrom.sh</a>
$ cat runQemu-on-base-img-cdrom.sh
#!/bin/bash
numsmp="4"
memsize="4G"
imgloc=${HOME}/"runQemu"/"runQemu-imgs"
isoloc=${HOME}/"runQemu"/"runQemu-imgs"
imgfile="ub1604raw.img"
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
$
</pre>
นศ สามารถแทนค่า shell variable ในคำสั่งด้วยตนเองถ้าต้องการออกคำสั่งรัน kvm (qemu-system-x86_64) ด้วยตนเอง สำหรับ script ข้างต้น พารามีเตอร์ที่กำหนดใช้กับคำสั่ง qemu-system-x86_64 ใน script มีความหมายดังนี้
<ul>
 <li> "-enable-kvm" : เรียก qemu ใน mode "kvm" คือให้ qemu ใช้ kvm driver บน linux เพื่อใช้ CPU virtualization supports
 <li> "-cpu host" : ให้ใช้ features ของ CPU ชอง host 
 <li> "-smp 4" : ให้ vm มี virtual cpu cores จำนวน 8 cores (qemu จะสร้าง threads  ขึ้น 8 threads เพื่อรองรับการประมวลผลของ vm)
 <li> "-m 4G" : vm มี memory 4 GiB
 <li> "-drive file..." : vm ใช้ไฟล์ ub1604raw.img เป็น harddisk drive ที่ 1 ผู้ใช้ต้องระบุว่าไฟล์เป็นแบบ raw format เพราะ qemu ต้องการ make sure ว่าผู้ใช้รู้จัวว่ากำลังใช้ raw format image อยู่ (ถ้าไม่ระบุ qemu จะเตือน) ในกรณีที่ นศ ใช้ qcow2 ก็ให้เปลี่ยน format=raw เป็น format=qcow2
 <li> "-boot d" : boot จาก cdrom
 <li> "-cdrom <file...>" : ไฟล์ iso ถ้าจะใช้ cdrom drive จริงต้องระบุ device (ขอให้ดูคู่มือ qemu)
 <li> "-vnc :95" : vm จะรัน vnc server เป็น console ที่ vnc port 95 (port จริง 5900+95)
 <li> "-net nic -net user" : กำหนดให้ network interface ที่ 1 ของ vm ใช้ NAT network
 <li> "-monitor tcp::9666..." : ให้ผู้ใช้เข้า qemu monitor ได้ที่ port 9666 บนเครื่อง localhost
 <li> "-localtime" : กำหนดให้ vm ใช้เวลาเดียวกับเครื่อง host 
</ul>
ขอให้ นศ สังเกตุว่า script นี้้จะรันคำสั่ง qemu-system-x86_64 ด้วย sudo 
<p><p>
สำหรับคำสั่ง taskset และตัวแปร CPULIST นั้นเราไม่ได้บังคับให้ใส่ แต่ที่ใส่ในที่นี้เพื่อกำหนดให้ qemu-kvm process (หรือ threads) สามารถรันบน CPU 0 ถึง 11 ของเครื่อง host (เนื่องจาก host อาจแบ่ง cpu อื่นที่มีสำหรับรันงานอื่น)
<p><p>
ต่อไปให้ นศ รัน script ด้วยคำสั่ง 
<pre>
$ ./runQemu-on-base-img-cdrom.sh &
$
</pre>
<p><p>
<a id="part3-1"><h3>3.1 การใช้ vnc console</h3></a>
<p><p>
ขอให้ นศ ติดตั้ง vnc client บนเครื่อง client computer ที่ นศ ใช้และกำหนด IP address ของเครื่อง host server (ในตัวอย่างของเราคือ 10.100.20.133) และ vnc port (จากที่กำหนดใน option "-vnc" ในตัวอย่างคือ 95) ดังภาพที่ 1 หลังจากกด connect แล้ว นศ จะเห็น vnc console ดังภาพที่ 2
<p>
  <img src="documents/vncclient1.png"> <br>
<p>
ภาพที่ 1
<p>
  <img src="documents/vncconsole1.png"> <br>
<p>
ภาพที่ 2
<p><p>
<a id="part3-1"><h3>3.2 แนะนำ qemu monitor</h3></a>
<p><p>
qemu monitor เป็น monitoring console ของ qemu ที่ใช้รอรับคำสั่งจากผู้ใช้ทาง keyboard เพื่อจัดการ vm เช่น ปิดเครื่อง สอบถามสถานะการทำงานและสถิติต่างๆ สั่งให้เครื่อง migrate หรือย้ายไปยังเครื่องอื่น และทำ snapshot ของ CPU และ Memory State เป็นต้น ปกติแล้ว ถ้า นศ <b>ไม่ได้</b>ระบุ option "-monitor tcp::9666..." นศ สามารถเข้าถึง qemu monitor ได้โดย กดปุ่ม ctrl-alt-2 บน vnc colnsole และ กดปุ่ม ctrl-alt-1 เพื่อเปลี่ยนหน้าจอกลับไปยัง console แต่เนื่องจาก นศ ได้ใช้ option ดังกล่าวแล้ว ก็จะใช้ ctrl-alt-2 บน vnc clnsole ไม่ได้ console จะแจ้งว่า "serial0 console" นศ ต้องใช้ nc utility บน bash command line บนเครื่อง host ของ นศ แทน (ในตัวอย่างนี้คือเครื่อง 10.100.20.133) 
<p><p>
<pre>
$ nc localhost 9666
$ nc localhost 9666
QEMU 2.9.0 monitor - type 'help' for more information
(qemu) help
...
(qemu) info
...
(qemu) กด ctrl-C เพื่อออก
$
</pre>
promt sign ของ qemu monitor คือ (qemu) ถ้า นศ กด help และ info จะมีข้อมูลมากมายแสดงคำสั่งต่างๆซึ่งเราจะยังไม่กล่าวถึงในที่นี่ นศ สามารถศึกษาเพิ่มเติมได้จาก wiki ของ qemu เมื่อต้องการออกจาก monitor กลับมาที่ bash shell ให้กด ctrl C
<p><p>
<a id="part3-1"><h3>3.3 ติดตั้ง guest OS แบบ btrfs file system บน raw disk</h3></a>
<p><p>
ในอับดับถัดไป ขอให้ นศ กลับไปพิจารณา vnc console และติดตั้ง ubuntu 16.04 server ถ้า นศ ต้องการติดตั้งแบบกำหนดให้ vm ใช้ ext4 file system ก็ทำได้เลยโดยเลือกการ partition และ format disk ตาม default ของ ubuntu
<p>
แต่ถ้า นศ ต้องการใช้ btrfs file system นศ สามารถทำได้ดังนี้ 
<ul>
<li>
<details>
<summary>ภาพ setup btrfs ที่ 1 </summary> 
  <p>
  <img src="documents/btrfssetup1.png"> <br>
</details>
<li>
<details>
<summary>ภาพ setup btrfs ที่ 2</summary> 
  <p>
  <img src="documents/btrfssetup2.png"> <br>
</details>
<li>
<details>
<summary>ภาพ setup btrfs ที่ 3</summary> 
  <p>
  <img src="documents/btrfssetup3.png"> <br>
</details>
<li>
<details>
<summary>ภาพ setup btrfs ที่ 4</summary> 
  <p>
  <img src="documents/btrfssetup4.png"> <br>
</details>
<li>
<details>
<summary>ภาพ setup btrfs ที่ 5</summary> 
  <p>
  <img src="documents/btrfssetup5.png"> <br>
</details>
<li>
<details>
<summary>ภาพ setup btrfs ที่ 6</summary> 
  <p>
  <img src="documents/btrfssetup6.png"> <br>
</details>
<li>
<details>
<summary>ภาพ setup btrfs ที่ 7</summary> 
  <p>
  <img src="documents/btrfssetup7.png"> <br>
</details>
<li>
<details>
<summary>ภาพ setup btrfs ที่ 8</summary> 
  <p>
  <img src="documents/btrfssetup8.png"> <br>
</details>
</ul>
หลังจากนั้นให้ นศ ติดตั้ง ubuntu ต่อตามปกติ หลังจากติดตั้งเสร็จ vm จะ reboot และกลับไปที่หน้าจอเริ่มต้นการติดตั้งใหม่ ให้ นศ ใช้คำสั่ง "quit" ใข qemu monitor เพื่อปิดเครื่อง vm
<p><p>
<pre>
$ nc localhost 9666
QEMU 2.9.0 monitor - type 'help' for more information
(qemu) quit
quit
$
[1]+  Done                    ./runQemu-on-base-img-cdrom.sh  (wd: ~/runQemu-temp/runQemu-scripts)
$
</pre>
หลังจากนั้นให้ นศ เรียกรัน qemu-kvm ขึ้นมาใหม่ด้วยคำสั่งข้างล่าง (นศ สามารถดูการสร้าง btrfs snapshot และการใช้งานได้ที่ <a href="https://www.youtube.com/playlist?list=PLmUxMbTCUhr57iyWg8UAZsEXQ9_lX3Ca5">youtube playlist นี้</a>)
<p><p>
<pre>
</pre>

<p><p>
<a id="part3-2"><h3>3.4 สร้าง disk แบบ qcow2 overlay</h3></a>
<p><p>
  

