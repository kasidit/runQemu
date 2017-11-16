# runQemu
<h1>การใช้ qemu-kvm สร้าง virtual machines บน ubuntu 16.04 server</h1>

<h2>1. กำหนดให้ ubuntu 16.04 host สนับสนุนการทำงานแบบ nested virtualization</h2>
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
<h2>2. สร้าง virtual hard disk ด้วย qemu-img</h2>
<p><p>
เราจะทดลองสร้าง disk image แบบต่างๆ แต่ก่อนอื่นเราต้องสร้าง disk เพื่อติดตั้ง guest OS ของ VM ในคำสั่งถัดไป นศ จะสร้าง disk image แบบ raw 
<p><p>
<h3>2.1 disk format แบบ raw</h3>
<p><p>
<pre>
$ cd $HOME
$ mkdir runQemu
$ cd runQemu
$ mkdir runQemu-img 
$ cd runQemu-img
$ wget http://releases.ubuntu.com/16.04/ubuntu-16.04.3-server-amd64.iso
$ ls
$ <b>qemu-img create -f raw ubuntu1604raw.img 16G</b>
Formatting 'ubuntu1604raw.img', fmt=raw size=17179869184
$ ls -l
total 844804
-rw-rw-r-- 1 kasidit kasidit   865075200 Sep 20 15:55 ubuntu-16.04.3-server-amd64.iso
<b>-rw-r--r-- 1 kasidit kasidit 17179869184 Nov 16 15:38 ubuntu1604raw.img</b>
$
</pre>
<p><p>
<h3>2.2 disk format แบบ qcow2</h3>
<p><p>
disk แบบ raw image จะใช้พื้นที่บน disk จริงเท่ากับที่ นศ ขอด้วยคำสั่ง qemu-img 
แต่ถ้าผมสร้าง image แบบ qcow2 นศ จะเห็นว่าขนาดของ disk เริ่มต้นจะไม่มากแต่จะขยายมากขึ้นเมื่อใช้งาน ข้อดีของ disk แบบ raw คือ performance 
ในขณะที่ข้อดีของแบบ qcow2 คือใช้พื้นที่เท่าที่ใช้จริง
<p><p>
<pre>
$ <b>qemu-img create -f qcow2 ubuntu1604qcow2.img 16G</b>
Formatting 'ubuntu1604qcow2.img', fmt=qcow2 size=17179869184 encryption=off cluster_size=65536 lazy_refcounts=off refcount_bits=16
$ ls -l
total 845000
-rw-rw-r-- 1 kasidit kasidit   865075200 Sep 20 15:55 ubuntu-16.04.3-server-amd64.iso
<b>-rw-r--r-- 1 kasidit kasidit      196864 Nov 16 15:49 ubuntu1604qcow2.img</b>
-rw-r--r-- 1 kasidit kasidit 17179869184 Nov 16 15:38 ubuntu1604raw.img
$
</pre>
<p><p>
<h2>3 การติดตั้ง ubuntu 16.04 บน virtual disks</h3>
<p><p>
<p><p>
<h3>3.1 ติดตั้ง guest OS แบบใช้ ext4 file system บน raw disk</h3>
<p><p>
<p><p>
<h3>3.2 สร้าง disk แบบ qcow2 overlay </h3>
<p><p>
  

