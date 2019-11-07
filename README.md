<h1>Tutorial: การใช้ qemu-kvm สร้าง virtual machines บน ubuntu 16.04 server</h1>
<ul>
 <li> <a href="#part0">1. ติดตั้ง qemu-kvm บน host server </a>
 <li> <a href="#part2">2. สร้าง virtual hard disk ด้วย qemu-img</a> 
      <ul>
       <li> <a href="#part2-2">2.1 disk format แบบ raw</a>
       <li> <a href="#part2-1">2.2 disk format แบบ qcow2</a>
      </ul>
<li> <a href="#part3">3 การติดตั้ง Guest OS แบบ ubuntu 16.04 บน virtual disks</a> 
      <ul>
       <li> <a href="#part3-1">3.1 การใช้ vnc console</a>
       <li> <a href="#part3-2">3.2 แนะนำ qemu monitor</a>
       <li> <a href="#part3-3">3.3 ติดตั้ง guest OS แบบ btrfs file system บน raw disk</a>
       <li> <a href="#part3-4">3.4 รัน vm หลังจากการติดตั้ง และใช้ NAT network</a>
       <li> <a href="#part3-5">3.5 สร้าง disk แบบ qcow2 overlay</a>
      </ul>
<li> <a href="#part4">4. การเชื่อมต่อ kvm เข้ากับ L2 Network ด้วย Linux Bridge</a>
      <ul>
       <li> <a href="#part4-1">4.1 ติดตั้ง bridge-utils และกำหนดค่า bridge br0 บน host</a>
       <li> <a href="#part4-2">4.2 กำหนดให้ kvm เชือมต่อกับ bridge br0 และรัน kvm</a>
      </ul>
<li> <a href="#part3">5. การเชื่อมต่อ kvm เข้ากับ subnet ใหม่ ด้วย openvswitch</a> 
<li> <a href="#part4">6. การสร้าง OpenVSwitch Virtual Network</a>
<li> <a href="#part1">7. กำหนดให้ ubuntu 16.04 host สนับสนุนการทำงานแบบ nested virtualization</a>
</ul>
<p><p>
ใน Tutorial นี้เราสมมุติว่า นศ มีเครื่องจริงหรือ host computer (เราจะกำหนดให้มี IP เป็น 10.100.20.151 ใน tutorial นี้) และสมมุติว่า นศ ต้องการจะติดตั้งและใช้ kvm เพื่อสร้าง virtual machine (vm) ที่มี Guest OS เป็น ubuntu 16.04  
<p>
Guide line ในการอ่าน tutorial นี้มีดังนี้ 
<ul>
<li>ในกรณีที่ นศ ต้องการให้ vm ที่ นศ สร้างขึ้นบนเครื่อง host สามารถรัน kvm ได้อีกชั้นหนึ่ง (nested virtualization) ขอให้ นศ อ่านวิธีการกำหนดค่าบนเครื่อง host ในส่วนที่ 7  
<li>ในส่วนที่ 3.3 นศ ต้องเลือกว่าจะติดตั้ง guest OS บน vm โดยใช้ ext4 หรือ btrfs การติดตั้งแบบ ext เพราะเป็น default ของ ubuntu 16.04 หาก นศ สนใจที่จะติดตั้ง btrfs บน ubuntu 16.04 และทดลองสร้างและใช้งาน btrfs snapshot เบื้องต้น ก็สามารถอ่านส่วนที่ 3.3 นี้ได้
<li>ใน tutorial นี้ นศ จะรัน qemu-kvm โดยเรียกใช้ qemu-* utilities บน commandlineโดยตรง (ไม่ทำผ่าน libvirt หรือ virsh)  
</ul>
<p><p>
<a id="part0"><h2>1. ติดตั้ง qemu-kvm บน host server</h2></a>
<p><p>
สมมุติว่า นศ มีเครื่อง host server เป็นเครื่อง ubuntu 16.04 อยู่เครื่องหนึ่ง และเครื่องนี้มี network inerface ที่ออก internet ได้ นศ สามารถติดตั้ง qemu-kvm ได้สองวิธีได้แก่ การติดตั้งโดยใช้ apt utility และการติดตั้งโดยการ compile จาก source code 
<p><p>
อย่างไรก็ตาม ก่อนอื่นเพื่อความสะดวก ให้ นศ 
login เข้า server และกำหนดให้ account ของ นศ สามารถใช้ sudo ได้โดยไม่ต้องใส่ password ดังนี้
<pre>
$ sudo nano /etc/sudoers
[sudo] password for ...
$
$ sudo cat /etc/sudoers
#
# This file MUST be edited with the 'visudo' command as root.
#
# Please consider adding local content in /etc/sudoers.d/ instead of
# directly modifying this file.
#
# See the man page for details on how to write a sudoers file.
#
Defaults        env_reset
Defaults        mail_badpass
Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
... ไม่เปลี่ยนแปลง ละไว้ไม่นำมาแสดงในที่นี้
#User privilege specification
root    ALL=(ALL:ALL) ALL

#Members of the admin group may gain root privileges
%admin ALL=(ALL) ALL

#Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) ALL
<b>openstack ALL=(ALL) NOPASSWD:ALL</b>

#See sudoers(5) for more information on "#include" directives:

#includedir /etc/sudoers.d
$
</pre>
เพิ่ม <b>openstack ALL=(ALL) NOPASSWD:ALL</b> เข้าไปใน # Allow members of group sudo to execute any command
<p><p>
ในกรณีติดตั้งโดยใช้ apt นศ สามารถใช้คำสั่งต่อไปนี้ แต่ถ้าจะติดตั้งโดยการ compile source code ขอให้ข้ามสองคำสั่งนี้ไป เพื่อความรวดเร็วขอให้กำหนดค่า repository ใน /etc/apt/sources.list ให้ใช้ th.archive.ubuntu.com repository 
<pre>
$ sudo apt-get update
$ sudo apt-get install qemu-kvm libvirt-bin ubuntu-vm-builder 
$
</pre>
<p><p>
การ compile และ install qemu-kvm บน ubintu 16.04 ทำดังต่อไปนี้ (อ้างอิงจาก https://wiki.qemu.org/Hosts/Linux) ในส่วนแรกจะเป็นการติดตั้ง required packages ได้แก่ git glib2.0-dev และ libfdt 
<pre>
$ sudo apt-get install git libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev
$ 
</pre>
ถัดจากนั้นก็เป็น recommended packages ถ้าจะทำใน command เดียวก็เป็น 
<pre>
$ sudo apt-get install git-email libaio-dev libbluetooth-dev libbrlapi-dev libbz2-dev \
libcap-dev libcap-ng-dev libcurl4-gnutls-dev libgtk-3-dev \
libibverbs-dev libjpeg8-dev libncurses5-dev libnuma-dev \
librbd-dev librdmacm-dev \
libsasl2-dev libsdl1.2-dev libseccomp-dev libsnappy-dev libssh2-1-dev \
libvde-dev libvdeplug-dev libvte-dev libxen-dev liblzo2-dev \
valgrind xfslibs-dev
$
</pre>
หรือจะแยกๆทำ ดังนี้ก็ได้
<pre>
$ sudo apt-get install git-email
$ sudo apt-get install libaio-dev libbluetooth-dev libbrlapi-dev libbz2-dev
$ sudo apt-get install libcap-dev libcap-ng-dev libcurl4-gnutls-dev libgtk-3-dev
$ sudo apt-get install libibverbs-dev libjpeg8-dev libncurses5-dev libnuma-dev
$ sudo apt-get install librbd-dev librdmacm-dev
$ sudo apt-get install libsasl2-dev libsdl1.2-dev libseccomp-dev libsnappy-dev libssh2-1-dev
$ sudo apt-get install libvde-dev libvdeplug-dev libvte-dev libxen-dev liblzo2-dev
$ sudo apt-get install valgrind xfslibs-dev
</pre>
หลังจากนั้นขอให้ download qemu-kvm จาก https://www.qemu.org/download/ และเลือ source code หรือใช้คำสั่งต่อไปนี้เพื่อ
download source code ของ qemu 4.1.0 และ extract source code (นศ อาจ clone จาก github ก็ได้แต่ไม่ได้ over ในที่นี้)
<pre>
$ wget https://download.qemu.org/qemu-4.1.0.tar.xz
$ ls -l
total 52740
-rw-rw-r-- 1 openstack openstack 54001708 Aug 16 02:49 qemu-4.1.0.tar.xz
$ tar xvf qemu-4.1.0.tar.xz 
$ ls -l
total 52744
drwxr-xr-x 49 openstack openstack     4096 Aug 16 02:01 qemu-4.1.0
-rw-rw-r--  1 openstack openstack 54001708 Aug 16 02:49 qemu-4.1.0.tar.xz
$
</pre>
ถัดไปคือการ configure และ make และ make install ซอฟต์แวร์นี้ ขอให้ นศ cd เข้าสู่ qemu-4.1.0 directory และ
สร้าง build subdirectory เพื่อเก็บ object ไฟล์ และไฟล์ชั่วคราวต่างๆที่ใช้ในการสร้าง และให้ cd สู่ build เพื่อรัน 
configure เพื่อกำหนด parameters ต่างๆ สำหรับการติดตั้งนี้
<pre>
$ cd qemu-4.1.0
$ mkdir build
$ cd build
$
$ ../configure -h

Usage: configure [options]
Options: [defaults in brackets after descriptions]

Standard options:
  --help                   print this message
  --prefix=PREFIX          install in PREFIX [/usr/local]
  --interp-prefix=PREFIX   where to find shared libraries, etc.
                           use %M for cpu name [/usr/gnemul/qemu-%M]
  --target-list=LIST       set target list (default: build everything)
                           Available targets: aarch64-softmmu alpha-softmmu
                           arm-softmmu cris-softmmu hppa-softmmu i386-softmmu
                           lm32-softmmu m68k-softmmu microblaze-softmmu
                           microblazeel-softmmu mips-softmmu mips64-softmmu
                           mips64el-softmmu mipsel-softmmu moxie-softmmu
                           nios2-softmmu or1k-softmmu ppc-softmmu ppc64-softmmu
                           riscv32-softmmu riscv64-softmmu s390x-softmmu
                           sh4-softmmu sh4eb-softmmu sparc-softmmu
                           sparc64-softmmu tricore-softmmu unicore32-softmmu
                           x86_64-softmmu xtensa-softmmu xtensaeb-softmmu
                           aarch64-linux-user aarch64_be-linux-user
                           alpha-linux-user arm-linux-user armeb-linux-user
                           cris-linux-user hppa-linux-user i386-linux-user
                           m68k-linux-user microblaze-linux-user
                           microblazeel-linux-user mips-linux-user
                           mips64-linux-user mips64el-linux-user
                           mipsel-linux-user mipsn32-linux-user
                           mipsn32el-linux-user nios2-linux-user
                           or1k-linux-user ppc-linux-user ppc64-linux-user
                           ppc64abi32-linux-user ppc64le-linux-user
                           riscv32-linux-user riscv64-linux-user
                           s390x-linux-user sh4-linux-user sh4eb-linux-user
                           sparc-linux-user sparc32plus-linux-user
                           sparc64-linux-user tilegx-linux-user
                           x86_64-linux-user xtensa-linux-user
                           xtensaeb-linux-user
  --target-list-exclude=LIST exclude a set of targets from the default target-list

Advanced options (experts only):
  --cross-prefix=PREFIX    use PREFIX for compile tools []
  --cc=CC                  use C compiler CC [cc]
  --iasl=IASL              use ACPI compiler IASL [iasl]
  --host-cc=CC             use C compiler CC [cc] for code run at
                           build time
  --cxx=CXX                use C++ compiler CXX [c++]
  --objcc=OBJCC            use Objective-C compiler OBJCC [cc]
  --extra-cflags=CFLAGS    append extra C compiler flags QEMU_CFLAGS
  --extra-cxxflags=CXXFLAGS append extra C++ compiler flags QEMU_CXXFLAGS
  --extra-ldflags=LDFLAGS  append extra linker flags LDFLAGS
  --cross-cc-ARCH=CC       use compiler when building ARCH guest test cases
  --cross-cc-flags-ARCH=   use compiler flags when building ARCH guest tests
  --make=MAKE              use specified make [make]
  --install=INSTALL        use specified install [install]
  --python=PYTHON          use specified python [python3]
  --smbd=SMBD              use specified smbd [/usr/sbin/smbd]
  --with-git=GIT           use specified git [git]
  --static                 enable static build [no]
  --mandir=PATH            install man pages in PATH
  --datadir=PATH           install firmware in PATH/qemu
  --docdir=PATH            install documentation in PATH/qemu
  --bindir=PATH            install binaries in PATH
  --libdir=PATH            install libraries in PATH
  --libexecdir=PATH        install helper binaries in PATH
  --sysconfdir=PATH        install config in PATH/qemu
  --localstatedir=PATH     install local state in PATH (set at runtime on win32)
  --firmwarepath=PATH      search PATH for firmware files
  --with-confsuffix=SUFFIX suffix for QEMU data inside datadir/libdir/sysconfdir [/qemu]
  --with-pkgversion=VERS   use specified string as sub-version of the package
  --enable-debug           enable common debug build options
  --enable-sanitizers      enable default sanitizers
  --disable-strip          disable stripping binaries
  --disable-werror         disable compilation abort on warning
  --disable-stack-protector disable compiler-provided stack protection
  --audio-drv-list=LIST    set audio drivers list:
                           Available drivers: oss alsa sdl pa
  --block-drv-whitelist=L  Same as --block-drv-rw-whitelist=L
  --block-drv-rw-whitelist=L
                           set block driver read-write whitelist
                           (affects only QEMU, not qemu-img)
  --block-drv-ro-whitelist=L
                           set block driver read-only whitelist
                           (affects only QEMU, not qemu-img)
  --enable-trace-backends=B Set trace backend
                           Available backends: dtrace ftrace log simple syslog ust
  --with-trace-file=NAME   Full PATH,NAME of file to store traces
                           Default:trace-<pid>
  --disable-slirp          disable SLIRP userspace network connectivity
  --enable-tcg-interpreter enable TCG with bytecode interpreter (TCI)
  --enable-malloc-trim     enable libc malloc_trim() for memory optimization
  --oss-lib                path to OSS library
  --cpu=CPU                Build for host CPU [x86_64]
  --with-coroutine=BACKEND coroutine backend. Supported options:
                           ucontext, sigaltstack, windows
  --enable-gcov            enable test coverage analysis with gcov
  --gcov=GCOV              use specified gcov [gcov]
  --disable-blobs          disable installing provided firmware blobs
  --with-vss-sdk=SDK-path  enable Windows VSS support in QEMU Guest Agent
  --with-win-sdk=SDK-path  path to Windows Platform SDK (to build VSS .tlb)
  --tls-priority           default TLS protocol/cipher priority string
  --enable-gprof           QEMU profiling with gprof
  --enable-profiler        profiler support
  --enable-debug-stack-usage
                           track the maximum stack usage of stacks created by qemu_alloc_stack

Optional features, enabled with --enable-FEATURE and
disabled with --disable-FEATURE, default is enabled if available:

  system          all system emulation targets
  user            supported user emulation targets
  linux-user      all linux usermode emulation targets
  bsd-user        all BSD usermode emulation targets
  docs            build documentation
  guest-agent     build the QEMU Guest Agent
  guest-agent-msi build guest agent Windows MSI installation package
  pie             Position Independent Executables
  modules         modules support (non-Windows)
  debug-tcg       TCG debugging (default is disabled)
  debug-info      debugging information
  sparse          sparse checker

  gnutls          GNUTLS cryptography support
  nettle          nettle cryptography support
  gcrypt          libgcrypt cryptography support
  auth-pam        PAM access control
  sdl             SDL UI
  sdl-image       SDL Image support for icons
  gtk             gtk UI
  vte             vte support for the gtk UI
  curses          curses UI
  iconv           font glyph conversion support
  vnc             VNC UI support
  vnc-sasl        SASL encryption for VNC server
  vnc-jpeg        JPEG lossy compression for VNC server
  vnc-png         PNG compression for VNC server
  cocoa           Cocoa UI (Mac OS X only)
  virtfs          VirtFS
  mpath           Multipath persistent reservation passthrough
  xen             xen backend driver support
  xen-pci-passthrough    PCI passthrough support for Xen
  brlapi          BrlAPI (Braile)
  curl            curl connectivity
  membarrier      membarrier system call (for Linux 4.14+ or Windows)
  fdt             fdt device tree
  bluez           bluez stack connectivity
  kvm             KVM acceleration support
  hax             HAX acceleration support
  hvf             Hypervisor.framework acceleration support
  whpx            Windows Hypervisor Platform acceleration support
  rdma            Enable RDMA-based migration
  pvrdma          Enable PVRDMA support
  vde             support for vde network
  netmap          support for netmap network
  linux-aio       Linux AIO support
  cap-ng          libcap-ng support
  attr            attr and xattr support
  vhost-net       vhost-net kernel acceleration support
  vhost-vsock     virtio sockets device support
  vhost-scsi      vhost-scsi kernel target support
  vhost-crypto    vhost-user-crypto backend support
  vhost-kernel    vhost kernel backend support
  vhost-user      vhost-user backend support
  spice           spice
  rbd             rados block device (rbd)
  libiscsi        iscsi support
  libnfs          nfs support
  smartcard       smartcard support (libcacard)
  libusb          libusb (for usb passthrough)
  live-block-migration   Block migration in the main migration stream
  usb-redir       usb network redirection support
  lzo             support of lzo compression library
  snappy          support of snappy compression library
  bzip2           support of bzip2 compression library
                  (for reading bzip2-compressed dmg images)
  lzfse           support of lzfse compression library
                  (for reading lzfse-compressed dmg images)
  seccomp         seccomp support
  coroutine-pool  coroutine freelist (better performance)
  glusterfs       GlusterFS backend
  tpm             TPM support
  libssh          ssh block device support
  numa            libnuma support
  libxml2         for Parallels image format
  tcmalloc        tcmalloc support
  jemalloc        jemalloc support
  avx2            AVX2 optimization support
  replication     replication support
  opengl          opengl support
  virglrenderer   virgl rendering support
  xfsctl          xfsctl support
  qom-cast-debug  cast debugging support
  tools           build qemu-io, qemu-nbd and qemu-img tools
  vxhs            Veritas HyperScale vDisk backend support
  bochs           bochs image format support
  cloop           cloop image format support
  dmg             dmg image format support
  qcow1           qcow v1 image format support
  vdi             vdi image format support
  vvfat           vvfat image format support
  qed             qed image format support
  parallels       parallels image format support
  sheepdog        sheepdog block driver support
  crypto-afalg    Linux AF_ALG crypto backend driver
  capstone        capstone disassembler support
  debug-mutex     mutex debugging support
  libpmem         libpmem support

NOTE: The object files are built at the place where configure is launched
$
</pre>
คำสั่ง configure -h ข้างต้น แสดงให้เห็นว่า qemu อนุญาตให้ นศ กำหนดค่าต่างๆได้มากมาย โดยที่เราจะกล่างถึงบางอย่าง
ที่สำคัญต่อการติดตั้งในอันดับถัดไปได้แก่ 
<ul>
  <li> prefix: เป็นตัวแปรสำหรับกำหนดตำแหน่งของ directory ที่หลังจาก compile เสร็จแล้วต้องการ install จะ install ที่ directory ใด 
   ถ้าไม่กำหนดค่า prefix ค่า default จะเป็นที่ /usr/local/bin
  <li> target-list: เป็นตัวแปรที่ใช้ระบุ list ของ ISA platforms ที่ นศ ต้องการให้ qemu emulate ยกตัวอย่างเช่นถ้า นศ ต้องการให้ qemu 
   รองรับ Guest OS ที่เป็น image ที่ประกอบไปด้วย ARM ISA ก็ต้องระบุ aarch64-softmmu เป็นต้น 
  <li> enable: เป็นที่ระบุว่าจะใช้ feature พิเศษใดที่ host server มีให้ ยกตัวอย่างเช่น kvm module สำหรับใช้งาน hardware-supported virtualization
</ul>
ในที่นี้เราจะกำหนดให้ติดตั้ง qemu binary ที่ $HOME/bin และเราจะสร้าง qemu-kvm แบบที่รัน Guest OS ที่ประกอบไปด้วยชุดคำสั่งที่ใช้ ISA x86_64 (64 bits) โดยใช้ hardware support และแบบที่รัน Guest OS ที่เป็น ISA x_86_64 โดยรันแบบ Emulation ใน User Mode ที่ไม่มี hardware supports 
<p><p>
หลังจากนั้นก็ compile ด้วยคำสั่ง "make" ซึ่งจะใช้เวลาพอสมควร และติดตั้งสู่ prefix directory ด้วย "make install"
<pre>
$ mkdir $HOME/qemu
$ echo $HOME
/home/openstack
$ ../configure --prefix=$HOME/qemu --target-list=x86_64-softmmu,x86_64-linux-user --enable-kvm
...
$
$ make
...
$ make install
...
$
</pre>
หลังจากการติดตั้งเสร็จสิ้น นศ ก็สามารถใช้ ubuntu ที่ติดตั้งได้ โดยที่จะมี binary ไฟล์เช่น qemu-system-x86_64 และ qemu-img อยู่ที่
prefix directory 
<p><p>
เพื่อความสะดวกใน section ถัดไปเราจะอ้างอิงการใช้งาน qemu จาก default directory (สำหรับกรณีทั่วๆไปที่ผู้ใช้มักจะติดตั้งจาก ubuntu repository 
เป็นส่วนใหญ่) 
<p><p>
 <a id="part2"><h2>2. สร้าง virtual hard disk image ด้วย qemu-img</h2></a>
<p><p>
<table>
<tr><td>
<b>แบบฝึกหัด:</b> ขอให้ นศ สร้าง virtual disk แบบ qcow2 ขนาด 8G  
</td></tr>
</table>
<p><p>
  <a id="part2-2"><h3>2.1 disk format แบบ qcow2</h3></a>
คำสั่ง qemu-img สร้าง image แบบ copy on write (เรียกว่า qcow2 format) ซึ่งจะสร้าง file เปล่าๆที่ประกอบไปด้วย data structures สำหรับการจัดระเบียบว่าข้อมูลต่างๆที่ถูกเขียนลงบน disk นี้จะถูกเก็บที่ไหนในไฟล์ disk image แต่เมื่อสร้าง file disk image นี้ขึ้นมาจะยังไม่จองพื้นที่จริง แต่จะใช้พื้นที่จริงเมื่อมีการเขียนข้อมูลลงสู่ disk หรือมีการเปลี่ยนแปลงข้อมูลเท่านั้น 
<p><p>ยกตัวอย่างเช่น เมื่อ นศ สร้าง disk image แบบ qcow2 ขนาด  GB นศ จะเห็นว่าขนาดของ qcow2 disk เริ่มต้นจะไม่ใหญ่มาก (197120 bytes) แต่จะขยายมากขึ้นเมื่อมีการเขียนข้อมูลสู่ disk จริง ข้อดีของ disk แบบนี้คือประหยัดพื้นที่ใช้งาน 
<p><p> เพื่อความสะดวกผมจะสร้าง directory ใหม่คือ $HOME/images เพื่อเก็บไฟล์ disk images
<pre>
$ mkdir images
$ cd images
$ qemu-img create -f qcow2 ubuntu1604qcow2.img 8G
Formatting 'ubuntu1604qcow2.img', fmt=qcow2 size=8589934592 encryption=off cluster_size=65536 lazy_refcounts=off refcount_bits=16
$ 
$ ls -l
total 196
-rw-r--r-- 1 openstack openstack 197120 Apr 19 04:03 ubuntu1604qcow2.img
$
</pre>
disk image แบบ qcow2 มี features ที่เราจะกล่าวถึงอีกประการคือการสร้าง disk image แบบ qcow2 overlay ซึ่งผมจะอธิบายอีกทีในภายหลัง 
<p><p>
  <a id="part2-1"><h3>2.2 disk format แบบ raw</h3></a>
<p><p>
virtual disk image แบบ raw นี้ จะใช้พื้นที่บน disk จริงเท่ากับปริมาณที่ขอตั้งแต่แรก มีข้อดีอ่านเขียนข้อมูลได้เร็วแต่มีข้อเสียคือใช้พื้นบน physical disk มาก
<p><p>
<pre>
$ qemu-img create -f raw ubuntu1604raw.img 8G
Formatting 'ubuntu1604raw.img', fmt=raw size=8589934592
$
$ ls -l
total 196
-rw-r--r-- 1 openstack openstack     197120 Apr 19 04:04 ubuntu1604qcow2.img
-rw-r--r-- 1 openstack openstack 8589934592 Apr 19 04:04 ubuntu1604raw.img
$
</pre>
<p><p>
  <a id="part3"><h2>3 การติดตั้ง Guest OS แบบ ubuntu 16.04 บน virtual disks</h2></a>
<p><p>
ในส่วนนี้ นศ จะเรียก qemu-kvm จาก command line เพื่อสร้าง Guest OS บน qcow2 disk image ที่สร้างขึ้น 
ก่อนอื่นผมต้อง download ไฟล์ iso image ของ ubuntu OS มาจากเก็บใน images directory 
<pre>
$ cd $HOME/images
$ wget http://releases.ubuntu.com/16.04/ubuntu-16.04.6-server-amd64.iso
$  
$ ls -l
total 894152
-rw-rw-r-- 1 openstack openstack  915406848 Mar 29 18:14 ubuntu-16.04.6-server-amd64.iso
-rw-r--r-- 1 openstack openstack     197120 Apr 19 04:04 ubuntu1604qcow2.img
-rw-r--r-- 1 openstack openstack 8589934592 Apr 19 04:04 ubuntu1604raw.img
$
</pre>
<table>
<tr><td>
<b>ข้อสังเกตุ:</b> ถ้าในเครื่องของ นศ มีไฟล์นี้อยู่แล้ว ก็ไม่ต้อง wget มาอีก 
</td></tr>
<p><p>
ในอันดับถัดไป ผมจะสร้าง directory ใหม่คือ $HOME/script และใช้ nano หรือ vi เขียนคำสั่งลงใน bash shell script "runQemu-on-base-qcow2-img-cdrom.sh" ใน directory นั้น 
</table>
<pre>
$ cd $HOME
$ mkdir scripts
$ cd scripts
$ 
$ which qemu-system-x86_64
/usr/bin/qemu-system-x86_64
$
$ nano runQemu-on-base-qcow2-img-cdrom.sh
$ 
$ cat runQemu-on-base-qcow2-img-cdrom.sh
#!/bin/bash
numsmp="2"
memsize="2G"
imgloc=${HOME}/images
isoloc=${HOME}/images
imgfile="ubuntu1604qcow2.img"
exeloc="/usr/bin"
#
sudo ${exeloc}/qemu-system-x86_64 \
     -enable-kvm -cpu host -smp ${numsmp} \
     -m ${memsize} \
     -drive file=${imgloc}/${imgfile},format=qcow2 \
     -boot d -cdrom ${isoloc}/ubuntu-16.04.6-server-amd64.iso \
     -vnc :95 \
     -net nic -net user \
     -localtime
$
</pre>
เราใช้คำสั่ง which เพื่อเช็คว่า qemu-system-x86_64 executable อยู่ใน directory ใด และพารามีเตอร์ที่กำหนดใช้กับคำสั่ง qemu-system-x86_64 ใน script มีความหมายดังนี้
<ul>
 <li> "-enable-kvm" : เรียก qemu ใน mode "kvm" คือให้ qemu ใช้ kvm driver บน linux เพื่อใช้ CPU hardware virtualization supports
 <li> "-cpu host" : ให้ใช้ CPU ของเครื่อง host 
 <li> "-smp 2" : ให้ VM เครื่องนี้มี virtual cpu cores จำนวน 2 cores (qemu-kvm จะสร้าง threads  ขึ้น 2 threads เพื่อรองรับการประมวลผลของ VM)
 <li> "-m 2G" : vm มี memory 2 GiB
 <li> "-drive file=${imgloc}/${imgfile},format=qcow2" : VM ใช้ไฟล์ที่กำหนดค่าตัวตัวแปร SHELL VARIABLE ${imgloc}/${imgfile} ซึ่งหมายถึง ${HOME}/images/ubuntu1604qcow2.img เป็น harddisk image ผู้ใช้ต้องระบุว่าไฟล์ format=qcow2 หมายถึงเป็น disk image แบบ qcow2 (ในกรณีที่ นศ ใช้ qcow2 ก็ให้เปลี่ยนเป็น format=raw)
 <li> "-boot d" : boot จาก cdrom
 <li> "-cdrom <file...>" : ไฟล์ iso ถ้าจะใช้ cdrom drive จริงต้องระบุชื่อ device บนเครื่อง host ของ cdrom นั้น
 <li> "-vnc :95" : VM นี้จะรัน vnc server เป็น console ที่ vnc port 95 (port จริง 5900+95)
 <li> "-net nic -net user" : กำหนดให้ network interface ที่ 1 ของ vm ใช้ NAT network
 <li> "-localtime" : กำหนดให้ vm ใช้เวลาเดียวกับเครื่อง host 
</ul>
ขอให้ นศ สังเกตุว่า script นี้้จะรันคำสั่ง qemu-system-x86_64 ด้วย sudo ซึ่งเรากำหนดไว้ตั้งแต่แรกแล้วว่าให้ใช้ได้โดยไม่ต้องป้อน password 
<p><p>
ในกรณีที่ นศ ต้องการใช้ qemu แทนที่จะเป็น kvm เนื่องจาก host ไม่มี hardware virtualization นศ จะต้องละ -enable-kvm และ -cpu host ออกไป
<p><p>
ต่อไปให้ นศ เปลี่ยน permission flag และรัน script ด้วยคำสั่ง 
<pre>
$ chmod 755 runQemu-on-base-img-cdrom.sh
$ ./runQemu-on-base-qcow2-img-cdrom.sh &
[2] 1728
$
</pre>
จะได้ VM รันเป็น backgroud process หนึ่งบนเครื่อง host
<p><p>
<a id="part3-1"><h3>3.1 การใช้ vnc console</h3></a>
<p><p>
ขอให้ นศ ติดตั้ง vnc client (ผมแนะนำ tightVNC และ VNC plugin บน chrome browser) บนเครื่อง notebook หรือ desktop computer ที่ นศ ใช้ และกำหนด IP address ของเครื่อง host server (ในตัวอย่างของเราคือ 10.100.20.151) และ vnc port (จากที่กำหนดใน option "-vnc" ในตัวอย่างคือ 95) ดังภาพที่ 1 หลังจากกด connect แล้ว นศ จะเห็น vnc console ดังภาพที่ 2 ในระหว่าติดตั้งขอให้ นศ ติดตั้ง OpenSSH Server ด้วย ในหน้า "Software Selection"
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
qemu monitor เป็น monitoring console ของ qemu ที่ใช้รอรับคำสั่งจากผู้ใช้ทาง keyboard เพื่อจัดการ vm เช่น ปิดเครื่อง สอบถามสถานะการทำงานและสถิติต่างๆ สั่งให้เครื่อง migrate หรือย้ายไปยังเครื่องอื่น และทำ snapshot ของ CPU และ Memory State เป็นต้น  นศ สามารถเข้าถึง qemu monitor ได้โดย กดปุ่ม ctrl-alt-2 บน vnc colnsole และ กดปุ่ม ctrl-alt-1 เพื่อเปลี่ยนหน้าจอกลับไปยัง console  
<p><p>
<pre>
QEMU 2.9.0 monitor - type 'help' for more information
(qemu) help
...
(qemu) info
...
(qemu) กด ctrl-alt-1 เพื่อ switch กลับไปหน้าจอปกติ
</pre>
promt sign ของ qemu monitor คือ (qemu) ถ้า นศ กด help และ info จะมีข้อมูลมากมายแสดงคำสั่งต่างๆซึ่งเราจะยังไม่กล่าวถึงในที่นี่ นศ สามารถศึกษาเพิ่มเติมได้จาก wiki ของ qemu เมื่อต้องการออกจาก monitor กลับมาที่ หน้าจอของ VM ให้กด ctrl-alt-1
<p><p>
<a id="part3-1"><h3>3.3 ติดตั้ง guest OS แบบ btrfs file system</h3></a>
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
หลังจากนั้นให้ นศ ติดตั้ง ubuntu ต่อตามปกติ 
<table>
<tr><td>
<details>
<summary>Click เพื่อศึกษาการสร้าง btrfs snapshot และ recover snashot</summary>
 <p>
เมื่อติดตั้งเสร็จแล้ว ให้ นศ login เข้าสู่เครื่องนั้นและดู btrfs subvolume ที่มีอยู่ในเครื่อง host ซึ่งหลังจากการติดตั้งข้างต้น ubuntu 16.04 จะสร้าง btrfs subvolmes สำหรับ / และ /home directory ให้ตั้งแต่เริ่มต้น
<pre>
$ sudo su
# df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            2.0G     0  2.0G   0% /dev
tmpfs           396M  5.5M  390M   2% /run
/dev/sda1        10G  2.0G  6.3G  25% /
tmpfs           2.0G     0  2.0G   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           2.0G     0  2.0G   0% /sys/fs/cgroup
/dev/sda1        10G  2.0G  6.3G  25% /home
tmpfs           396M     0  396M   0% /run/user/1000
# 
# mount /dev/sda1 /mnt 
#
</pre>
นศ ควร modify ไฟล์ /etc/fstab ด้วยการเพิ่มบรรทัดข้างล่าง เพื่อให้มีการสร้าง /mnt directory และ mount เข้ากับ /dev/sda1 device โดยอัตโนมัติเมื่อมีการ reboot
<p><p>
<pre>
# vi /etc/fstab
...
/dev/sda1       /mnt            btrfs   defaults   0    1
...
(ให้เซฟไฟล์ และออกจาก vi)
#
</pre>
ในอันดับถัดไป นศ list btrfs subvolume ซึ่ง ubuntu จะสร้าง subvolume /mnt/@ สำหรับ / directory และ /mnt/@home สำหรับ /home directory
<p><p>
<pre>
# btrfs subvolume list /mnt
ID 261 gen 7810 top level 5 path @
ID 262 gen 7702 top level 5 path @home
#
</pre>
นศ สามารถทำ defragmentation ด้วยคำสั่งต่อไปนี้
<p><p>
<pre>
# btrfs filesystem defrag /mnt
</pre>
นศ สามารถทำ snapshot ของ /mnt/@ และ /mnt/@home ดังนี้
<p><p>
<pre>
# <b>btrfs subvolume snapshot /mnt/@ /mnt/@_snapshot1</b>
Create a snapshot of '/mnt/@' in '/mnt/@_snapshot1'
# <b>btrfs subvolume snapshot /mnt/@home /mnt/@home_snapshot1</b>
Create a snapshot of '/mnt/@home' in '/mnt/@home_snapshot1'
# btrfs subvolume list /mnt
ID 261 gen 7812 top level 5 path @
ID 262 gen 7813 top level 5 path @home
ID 264 gen 7812 top level 5 path @_snapshot1
ID 265 gen 7813 top level 5 path @home_snapshot1
#
</pre>
หลังจากนั้น ถ้า นศ ใช้งาน directory / และ /home แล้วเกิดควาผิดพลาดขึ้น นศ สามารถกู้คืน / และ /home ด้วยคำสั่งต่อไปนี้ 
<p><p>
<pre>
# mv /mnt/@ /mnt/@_badroot
# mv /mnt/@home /mnt/@_badhome
# mv /mnt/@_snapshot1 /mnt/@
# mv /mnt/@home_snapshot1 /mnt/@home
#
# reboot
</pre>
เมื่อ reboot เสร็จ ให้ login เข้าเครื่อง sudo เป็น root แล้ว ลบ /mnt/@_badroot และ /mnt/@_badhome
<p><p>
<pre>
# btrfs subvolume delete /mnt/@_badroot
# btrfs subvolume delete /mnt/@_badhome
</pre>
หลังจากนั้นให้สร้าง snapshot ของ /mnt/@ และ /mnt/@home อีกครั้งหนึ่ง และทำ defragmentation ด้วยคำสั่งต่อไปนี้
<p><p>
<pre>
# btrfs subvolume snapshot /mnt/@ /mnt/@_snapshot1
# btrfs subvolume snapshot /mnt/@home /mnt/@home_snapshot1
# btrfs filesystem defrag /mnt
</pre>
ผม recommend ให้ นศ ทำ snapshot ของ /mnt/@ และ /mnt/@home ในระหว่างที่ใช้งาน file system เป็นระยะๆ (ภายใต้ชื่ที่แตกต่างจาก @_snapshot1 และ @home_snapshot1) เผื่อว่าเกิดความผิดพลาดขึ้น นศ จะได้ recover ข้อมูลจาก snapshots เหล่านั้น ได้ (นศ สามารถดูการสร้าง btrfs snapshot และการใช้งานได้ที่ <a href="https://www.youtube.com/playlist?list=PLmUxMbTCUhr57iyWg8UAZsEXQ9_lX3Ca5">youtube playlist นี้</a>)
</details>
</td></tr>
</table>

<p><p>
<a id="part3-3"><h3>3.4 รัน vm หลังจากการติดตั้งและใช้ NAT network</h3></a>
<p><p>
หลังจากติดตั้งเสร็จ VM จะ reboot และกลับไปที่หน้าจอเริ่มต้นการติดตั้งใหม่ ให้ นศ ใช้คำสั่ง "quit" ใข qemu monitor (กด ctrl-alt-1 บนหน้าจอ VNC) เพื่อปิดเครื่อง VM
<p><p>
<pre>
QEMU 2.9.0 monitor - type 'help' for more information
(qemu) quit
quit
</pre>
<p><p> นศ ต้องสร้าง script ไฟล์ใหม่ดังนี้ 
<pre>
$ cd $HOME/script
$ cp runQemu-on-base-qcow2-img-cdrom.sh runQemu-on-base-qcow2-img.sh
$ nano runQemu-on-base-qcow2-img.sh
$ 
$ cat runQemu-on-base-qcow2-img.sh
#!/bin/bash
numsmp="2"
memsize="2G"
imgloc=${HOME}/images
isoloc=${HOME}/images
imgfile="ubuntu1604qcow2.img"
exeloc="/usr/bin"
#
sudo ${exeloc}/qemu-system-x86_64 \
     -enable-kvm -cpu host -smp ${numsmp} \
     -m ${memsize} \
     -drive file=${imgloc}/${imgfile},format=qcow2 \
     <b>-boot c </b> \
     -vnc :95 \
     -net nic -net user \
     -localtime
$
</pre>
ขอให้ นศ สังเกตุว่า "-boot c" หมายถึง boot vm จาก hard disk image แทนที่จะเป็นจาก cdrom
<p><p>
 หลังจากนั้นให้ นศ รัน qemu-kvm ขึ้นมาใหม่ด้วยคำสั่งข้างล่าง 
<pre>
$ ./runQemu-on-base-qcow2-img.sh &
...
$ 
</pre>
หลังจากนั้น นศ สามารถเข้าใช้งาน VM ได้ทาง VNC โดยระบุ VNC endpoint (ในตัวอย่างของเราคือ 10.100.20.151:95)
<p><p>
<p><p>
สำหรับการติดต่อสื่อสารกับ network เครื่อง vm ที่ นศ เพิ่งรันด้วย option "-net nic -net user" จะมีการเชื่อมต่อกับ network ดังภาพที่ 3 
<p><p>
  <img src="documents/qemuNATnetwork2.png" width="400" height="300"> <br>
ภาพที่ 3
<p><p>
จากภาพเครื่อง vm เชื่อมต่อกับ host แบบ NAT network ด้วย Slirp protocol และมี subnet ระหว่าง host กับ vm คืออยู่ในวง 10.0.2.0 
โดยที่ host จะมี IP address คือ 10.0.2.2 และ vm จะมี IP address คือ 10.0.2.15 subnet นี้เป็น subnet ภายในที่อยู่ภายใต้ namespace 
เฉพาะ ระหว่าง host กับ vm แต่ละ vm เป็นคู่ๆไปเท่านั้น ด้วยเหตุนี้ นศ จะติดต่อสื่อสารจาก client โปรแกรมภายใน vm ออกสู่โลกภายนอกได้ 
แต่ client โปรแกรมจากภายนอก vm จะไม่สามารถสื่อสารกับโปรแกรม server ภายใน vm ได้ 
<p><p>
เมื่อ นศ ใช้ VNC client เชื่อมต่อเข้าใช้งาน VM ที่สร้างขึ้นแล้ว นศ สามารถตรวจสอบสถานะของ network ได้โดยใช้คำสั่งต่อไปนี้  เราจะสมมุติว่า นศ ได้ login เข้าสู่ vm ที่สร้างขึ้นใหม่แล้ว และเพื่อความสะดวกในการอธิบาย ผมจะใช้ "vm$" เป็นตัวแทน command line prompt ของ shell ของเครื่อง VM
<pre>
... login เข้าสู่ VM แล้ว ...
vm$ 
vm$ ifconfig 
จะเห็นว่า ens3 มี IP address คือ 10.0.2.15
vm$ 
</pre>
<p><p>
<a id="part3-4"><h3>3.5 สร้าง disk แบบ qcow2 overlay</h3></a>
<p><p>
ที่ผ่านมาผมได้ติดตั้ง ubuntu 16.04 บน image ubuntu1604qcow2.img ในอันดับถัดไป ผมจะสร้าง image ชนิด qcow2 แบบที่เรียกว่า overlay image ซึ่งเป็นไฟล์ที่แตกต่างจากแบบ raw และ qcow2 ธรรมดา ก็คือมันเป็นไฟล์ที่เก็บเฉพาะข้อมูลที่แตกต่างจาก image ที่เป็น base image ของมัน โดยที่เนื้อหาของ base image จะเหมือนเดิมและไม่เปลี่ยนแปลง การเปลี่ยนแปลงจะเกิดขึ้นที่ overlay image แทน format ของ base image จะเป็น qcow2 หรือ raw ก็ได้ แต่ format ของ overlay image เป็น qcow2 เท่านั้น
<p><p>
ในคำสั่งถัดไป ผมจะลบไฟล์ raw image ทิ้งเพื่อประหยัดเนื้อที่และ overlay image ชื่อว่า ubuntu1604qcow2.ovl ขึ้นมาบน base image "ubuntu1604qcow2.img"
<p><p>
<pre>
$ cd $HOME/images
$ rm ubuntu1604raw.img
$ qemu-img create -f qcow2 -b ubuntu1604qcow2.img ubuntu1604qcow2.ovl
Formatting 'ubuntu1604qcow2.ovl', fmt=qcow2 size=8589934592 backing_file=ubuntu1604qcow2.img encryption=off cluster_size=65536 lazy_refcounts=off refcount_bits=16
$
$ $ ls -l
total 3056208
-rw-rw-r-- 1 openstack openstack  915406848 Mar 29 18:14 ubuntu-16.04.6-server-amd64.iso
-rw-r--r-- 1 openstack openstack 2214002688 Apr 19 06:02 ubuntu1604qcow2.img
-rw-r--r-- 1 openstack openstack     197120 Apr 20 04:07 ubuntu1604qcow2.ovl
$ 
$ $ qemu-img info ubuntu1604qcow2.ovl
image: ubuntu1604qcow2.ovl
file format: qcow2
virtual size: 8.0G (8589934592 bytes)
disk size: 196K
cluster_size: 65536
backing file: ubuntu1604qcow2.img
Format specific information:
    compat: 1.1
    lazy refcounts: false
    refcount bits: 16
    corrupt: false
$
</pre>
จากคำสั่งข้างต้นไฟล์ ubuntu1604qcow2.ovl มี base image คือไฟล์ ubuntu1604raw.img นั่นหมายความว่า <b>กรณีที่ 1</b> เมื่อ kvm หรือ qemu อ่านค่าจากไฟล์ ubuntu1604qcow2.ovl และข้อมูล block ที่ต้องการยังไม่ได้รับการแก้ไขใดๆ ข้อมูลใน block เดียวกันจากไฟล์ base image ก็ถูกอ่านไปใช้งาน <b>กรณีที่ 2</b> kvm เขียนหรือแก้ไขข้อมูลใน block ของ ubuntu1604qcow2.ovl ที่ไม่เคยมีการเขียนหรือแก้ไขข้อมูลมาก่อน driver ของไฟล์แบบ qcow2 overlay นี้จะ copy ข้อมูลที่มีอยู่แล้วทั้ง block จากไฟล์ base image มายัง ubuntu1604qcow2.ovl หรือไฟล์ overlay และทำการเขียนข้อมูลลงใน copy ใหม่นั้น (หลักการ copy-on-write) <b>กรณีที่ 3</b> ถ้า block ที่จะอ่านหรือแก้ไขข้อมูลมี copy อยู่ในไฟล์ overlay แล้ว kvm จะอ่านข้อมูลจาก copy นั้นหรือเขียนข้อมูลลงใน copy นั้นทันที
<p><p>
ประโยชน์ของไฟล์แบบ overlay คือ ทำให้เราสามารถเก็บข้อมูลที่ไม่ต้องการให้ถูกเปลี่ยนแปลงใน base image ได้ <b>นศ สามารถสร้าง overlay ซ้อนกันหลายชั้นก็ได้</b> แต่ยิ่งจำนวนชั้นมากประสิทธิภาพของการอ่านข้อมูลก็จะช้าลงเพราะอาจต้องเปิดไฟล์หลายไฟล์ 
<p><p>
คำสั่งถัดไปจะเป็นการรัน qemu-kvm บนไฟล์ overlay "ubuntu1604qcow2.ovl" 
<pre>
$
$ cd $HOME/scripts
$ ls
runQemu-on-base-qcow2-img-cdrom.sh  runQemu-on-base-qcow2-img.sh
$ 
$ cp runQemu-on-base-qcow2-img.sh runQemu-on-base-qcow2-ovl.sh
$ nano runQemu-on-base-qcow2-ovl.sh
$ cat runQemu-on-base-qcow2-ovl.sh
#!/bin/bash
numsmp="2"
memsize="2G"
imgloc=${HOME}/images
isoloc=${HOME}/images
imgfile="ubuntu1604qcow2.ovl"
exeloc="/usr/bin"
#
sudo ${exeloc}/qemu-system-x86_64 \
     -enable-kvm \
     -cpu host -smp ${numsmp} \
     -m ${memsize} -drive file=${imgloc}/${imgfile},format=qcow2 \
     -boot c \
     -vnc :95 \
     -net nic -net user \
     -localtime
$
$ ./runQemu-on-base-qcow2-ovl.sh &
[1] 19540
$
</pre>
หลังจากนั้นผมใช้ vnc client 10.100.20.151:95 เข้าไป login เข้า VM และทำ sudo apt-get update  
<pre>
vm$ sudo apt update 
vm$ ifconfig 
จะเห็นว่า IP address คือ 10.0.2.15
vm$ sudo sed -i "s/us.arch/th.arch/g" /etc/apt/sources.list
vm$ sudo apt update
...
vm$ 
</pre>
หมายเหตุ: นศ สามารถศึกษาเพิ่มเติมเกี่ยวกับ qemu network ได้ที่ https://wiki.qemu.org/Documentation/Networking และ https://en.wikibooks.org/wiki/QEMU/Networking
<p><p>
บนเครื่อง host 10.100.20.151 ผมใช้ ls -l ใน shell จะเห็นความเปลี่ยนแปลงของไฟล์ ubuntu1604qcow2.ovl 
<pre>
$ cd $HOME/images
$ ls -l 
total 3566356
-rw-rw-r-- 1 openstack openstack  915406848 Mar 29 18:14 ubuntu-16.04.6-server-amd64.iso
-rw-r--r-- 1 openstack openstack 2214002688 Apr 19 06:02 ubuntu1604qcow2.img
-rw-r--r-- 1 openstack openstack  522649600 Apr 20 05:05 ubuntu1604qcow2.ovl
$
</pre>
<b>การ commit การเปลี่ยนแปลง จาก overlay image ไปยัง base image</b> สมมุติว่าหลังจากที่ทำงานเสร็จ ผมพอใจกับเนื้อหาใหม่ใน overlay ไฟล์ และอยาก merge ข้อมูลใหม่ลงสู่ไฟล์ base image สามารถทำได้ดังนี้
<p><p>
ก่อนอื่นเพื่อความปลอดภัยในการใช้งาน image ทั้งสองไฟล์ ผมจะหยุดการทำงานของ vm ก่อน โดยกด ctr-alt-2 ที่หน้าจอ VNC 
<p><p>
<pre>
QEMU 2.5.0 monitor - type 'help' for more information
(qemu) quit
</pre>
<p><p>
หลังจากนั้น ผมออกคำสั่งบน command line บน host 10.100.20.151 เพื่อ merge เนื้อหาของ overlay image เข้ากับ base image   
<pre>
$ cd $HOME/images
$ qemu-img info ubuntu1604qcow2.ovl
image: ubuntu1604qcow2.ovl
file format: qcow2
virtual size: 8.0G (8589934592 bytes)
disk size: 498M
cluster_size: 65536
backing file: ubuntu1604qcow2.img
Format specific information:
    compat: 1.1
    lazy refcounts: false
    refcount bits: 16
    corrupt: false
$
$ qemu-img commit ubuntu1604qcow2.ovl
Image committed.
$ ls -l
total 3211216
-rw-rw-r-- 1 openstack openstack  915406848 Mar 29 18:14 ubuntu-16.04.6-server-amd64.iso
-rw-r--r-- 1 openstack openstack 2372665344 Apr 20 05:14 ubuntu1604qcow2.img
-rw-r--r-- 1 openstack openstack     262144 Apr 20 05:14 ubuntu1604qcow2.ovl
$
</pre>
นศ จะเห็นว่ามีการเปลี่ยนแปลงในไฟล์ base และขนาดของ overlay ลดลง
<p><p>
<p><p>
  <a id="part4"><h2>4. การเชื่อมต่อ qemu kvm เข้ากับ L2 Network ด้วย Linux Bridge</h2></a>
<p><p>
ในกรณีที่ นศ ต้องการเข้าถึง VM จาก network ได้และต้องการให้ vm มี
IP address ที่อยู่ในวงเดียวกันกับ host (10.100.20.151) นศ สามารถกำหนดให้ VM ใช้ bridge network ซึ่งมีลักษณะการเชื่อมต่อระหว่าง 
vm กับโลกภายนอกดังภาพที่ 4 โดย bridge network จะอนุญาตให้เรากำหนด IP address ของ VM ให้อยู่ในวงเดียวกันกับของ host ได้ โดยในที่นี้เราจะกำหนดให้ VM มี IP เป็น 10.100.20.201
<p><p>
  <img src="documents/qemuBridgenetwork2.png" width="400" height="300"> <br>
ภาพที่ 4
<p><p>
หมายเหตุ: นศ สามารถศึกษาเพิ่มเติมเกี่ยวกับ qemu network ได้ที่ https://wiki.qemu.org/Documentation/Networking และ https://en.wikibooks.org/wiki/QEMU/Networking
<p><p>
  <a id="part4-1"><h3>4.1 ติดตั้ง bridge-utils และกำหนดค่า bridge br0 บน host</h3></a>
<p><p>
บนเครื่อง host 10.100.20.151 ผมใช้คำสั่งต่อไปนี้เพื่อติดตั้ง bridge util tool และเช็ค network interface configuration ปัจจุบันในไฟล์ /etc/network/interfaces
<pre>
$ sudo apt-get update
$ sudo apt-get install bridge-utils
...
$ cat /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
auto ens3
iface ens3 inet static
address 10.100.20.151
netmask 255.255.255.0
network 10.100.20.0
gateway 10.100.20.1
dns-nameservers 8.8.8.8
$
</pre>
<p><p>
ในอันดับถัดไปผมจะกำหนดค่าในไฟล์ /etc/network/interfaces เพื่อ 
<ul>
 <li>สั่งให้ bridge utility ใน linux kernel จะสร้าง virtual switch ชื่อ br0 ขึ้น 
 <li>ยกเลิกการกำหนดค่า IP address บน ens3 และกำหนดให้ ens3 เป็น port หนึ่งของ br0 และ
 <li>กำหนดให้ br0 เป็น network interface หลักของ Linux network stack ของ host โดยกำหนด IP address สำหรับ สำหรับ br0 interface เป็น 10.100.20.151 แทน ens3 
</ul>
<p><p>
โดยใช้คำสั่งต่อไปนี้บนเครื่อง host  
<pre>
$ sudo nano /etc/network/interfaces
$
$ cat /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto ens3
iface ens3 inet manual

auto br0
iface br0 inet static
   address 10.100.20.151
   netmask 255.255.255.0
   gateway 10.100.20.1
   bridge_ports    <b>ens3</b>
   bridge_stp      off
   bridge_maxwait  0
   bridge_fd       0
   dns-nameservers 8.8.8.8
$
$ sudo reboot 
</pre>
ค่าในไฟล์นี้มีความหมายว่า เรากำหนดให้ ens3 ไม่เป็น interface ของ Linux 
Network Stack ของเครื่อง host แต่จะมีการกำหนดค่าในภายหลัง 
<p><p>
ถัดจากนั้น กำหนดให้ br0 เป็น virtual switch (หรือ 
Linux bridge) และให้มันเป็น interface ของ Linux Network Stack ของ host และมี 
IP address คือ 10.100.20.151 และกำหนดให้ ens3 เป็น port หนึ่งของ br0
นศ สามารถ restart network ด้วยคำสั่งข้างล่าง (หรือ reboot ระบบด้วยคำสั่ง "sudo reboot" ก็ได้)
<pre>
$ sudo service networking restart 
</pre>
หลังจากนั้น (กรณี reboot ให้ login เข้าสู่ระบบ) นศ สามารถใช้คำสั่ง brctl เพื่อจัดการ bridge network บนเครื่อง 
host ของ นศ และใช้คำสั่ง "brctl show" เพื่อแสดงว่ามี virtual switch (หรือ Linux bridge) อะไรอยู่บนเครื่อง host 
ของ นศ บ้าง ในที่นี่ นศ จะเห็นว่า br0 อยู่และ br0 มี ens3 ต่ออยู่กับมัน
<p><p>
<pre>
$ brctl
Usage: brctl [commands]
commands:
        addbr             add bridge
        delbr             delete bridge
        addif             add interface to bridge
        delif             delete interface from bridge
        hairpin           turn hairpin on/off
        setageing         set ageing time
        setbridgeprio     set bridge priority
        setfd             set bridge forward delay
        sethello          set hello time
        setmaxage         set max message age
        setpathcost       set path cost
        setportprio       set port priority
        show              show a list of bridges
        showmacs          show a list of mac addrs
        showstp           show bridge stp info
        stp               turn stp on/off
$
$
$ brctl show
bridge name     bridge id               STP enabled     interfaces
br0             8000.007159272b80       no              ens3
virbr0          8000.5254000d09ec       yes             virbr0-nic
$
</pre>
<p><p>
  <a id="part4-2"><h3>4.2 กำหนดให้ kvm เชือมต่อกับ bridge br0 และรัน kvm </h3></a>
<p><p>
นศ ต้องสร้าง script ไฟล์ สองไฟล์ที่ kvm จะเรียกเพื่อสร้าง tap interface เชื่อมต่อกับ bridge br0 ที่เราเพิ่สร้างขึ้น
<pre>
$ cd
$ mkdir ${HOME}/etc
$ cd etc
$ nano qemu-ifup
$ chmod 755 qemu-ifup
$
$ cat qemu-ifup
#!/bin/sh
# switch=$(/sbin/ip route list | awk '/^default / { print $5 }')
switch=br0
/sbin/ifconfig $1 0.0.0.0 promisc up
/sbin/brctl addif ${switch} $1
$
$ nano qemu-ifdown
$ chmod 755 qemu-ifdown
$
$ cat ${HOME}/etc/qemu-ifdown
#!/bin/sh
# switch=$(/sbin/ip route list | awk '/^default / { print $5 }')
switch=br0
/sbin/ifconfig $1 down
/sbin/brctl delif ${switch} $1
$
</pre>
qemu-ifup จะถูกใช้โดย qemu-kvm เพื่อเพิ่ม TAP network interface ของ VM เข้ากับ br0 ส่วน qemu-ifdown จะลบ TAP interface ออก
TAP interface เป็นไฟล์ที่ถูกสร้างขึนเป็นพื้นที่ใช้ส่ง Ethernet frame ระหว่าง processes ใน Linux
<p><p>
รัน qemu-kvm ด้วยคำสั่งนี้ ขอให้สังเกตุ option "script" และ "downscript"
<pre>
$ cd
$ cd scripts
$ cp runQemu-on-base-qcow2-ovl.sh runQemu-on-br-network.sh
$ nano runQemu-on-br-network.sh
$ cat runQemu-on-br-network.sh
#!/bin/bash
numsmp="2"
memsize="2G"
imgloc=${HOME}/images
isoloc=${HOME}/images
imgfile="ubuntu1604qcow2.ovl"
exeloc="/usr/bin"
#
sudo ${exeloc}/qemu-system-x86_64 \
     -enable-kvm \
     -cpu host -smp ${numsmp} \
     -m ${memsize} -drive file=${imgloc}/${imgfile},format=qcow2 \
     -boot c \
     -vnc :95 \
     -netdev type=tap,script=${HOME}/etc/qemu-ifup,downscript=${HOME}/etc/qemu-ifdown,id=hostnet10 \
     -device virtio-net-pci,romfile=,netdev=hostnet10,mac=00:71:50:00:01:51 \
     -localtime
$
$ ./runQemu-on-br-network.sh &
...
$
</pre>
<p><p>
คำสั่งนี้จะทำให้เรารัน VM ขึ้นมา แต่เนื่องจาก network ที่เราใช้เป็น static network ไม่ได้ assign IP ให้อัตโนมัติแบบ DHCP 
ดังนั้น ubuntu guest OS ใน VM จะรอประมาณ 5 นาที ก่อนที่จะเข้าสู่ login screen 
<p><p> 
เนื่องจากเรายังไม่ได้ กำหนดค่า IP ของ tap interface ของ vm ที่เพิ่งรันให้อยู่ในวง 10.100.20.x เรายังไม่สามารถ putty เข้าสู่ vm ได้ เราต้องกำหนด network เริ่มต้นโดยใช้ vnc client console ซึ่งสามารถเข้าถึงที่ vnc endpoint 10.100.20.151:95 เมื่อเข้าสู่ vnc console แล้วให้ นศ กำหนดค่าในไฟล์ /etc/network/interfaces ของ vm ดังนี้ แล้ว restart network (หมายเหตุ ผมเปลี่ยน prompt sign ของ vm ให้เป็น "vm$" 
<p><p>
<pre>
vm$ cat /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback

auto ens3
iface ens3 inet static
address 10.100.20.201
netmask 255.255.255.0
network 10.100.20.0
gateway 10.100.20.1
dns-nameservers 8.8.8.8
vm$ 
vm$ sudo ifdown ens3
vm$ sudo ifup ens3
vm$
vm$ ping www.google.com
...
vm$
</pre>
นศ จะเห็นว่าขณะนี้ทั้ง host และ vm อยู่ในวง subnet เดียวกันคือวง 10.100.20.0/24 
<p><p>
จากเครื่อง 10.100.20.151 นศ สามารถใช้ putty login เข้าสู่เครื่อง 10.100.20.201 ได้
<p><p>
 <b>แบบฝึกหัด</b> ขอให้ นศ สร้าง VM อีกเครื่องหนึ่งให้ใช้ IP 10.100.20.211
<p><p>
<a id="part5"><h2>5. การเชื่อมต่อ kvm เข้ากับ subnet ใหม่ ด้วย openvswitch</h2></a>
<p><p>
<p><p>
  <img src="documents/qemuOVSlocalbr1.PNG"> <br>
ภาพที่ 5
<p><p>
TBA
<pre>
$ sudo apt install openvswitch-switch
$ sudo ovs-vsctl add-br br-int
$ sudo ovs-vsctl add-port br-int gw1 -- set interface gw1 type=internal
$ sudo ip addr add 10.90.0.1/24 dev gw1
$ ifconfig gw1
</pre>
สำหรับการกำหนดค่า IP ของ gw1 นศ สามารถกำหนดใน /etc/network/interfaces ได้ด้วย ซึ่งจะทำให้ gw1 มีค่านี้ถาวรในกรณีที่มีการ reboot
<p><p>
นศ ต้องสร้าง ovs-ifup script ให้ qemu เรียกเพื่อสร้าง interface เชื่อมต่อกับ br-int
<pre>
$ cd $HOME/etc
$ nano ovs-ifup
$ cat ovs-ifup
#!/bin/sh
switch='br-int'
/sbin/ifconfig $1 0.0.0.0 up
ovs-vsctl add-port ${switch} $1
$
</pre>
และสร้าง ovs-ifdown script ให้ qemu เรียกเพื่อลบ interface ออกจาก br-int
<pre>
$ nano ovs-ifdown
$ cat ovs-ifdown
#!/bin/sh
switch='br-int'
/sbin/ifconfig $1 0.0.0.0 down
$
</pre>
<p><p>
สร้าง qemu script ที่ใช้ openvswitch network (OVS network) และรัน VM
<pre>
$ cd scripts
$ cp runQemu-on-br-network.sh runQemu-on-ovs-network.sh
$ nano runQemu-on-ovs-network.sh
$ cat runQemu-on-ovs-network.sh
#!/bin/bash
numsmp="2"
memsize="2G"
imgloc=${HOME}/images
isoloc=${HOME}/images
imgfile="ubuntu1604qcow2.ovl"
exeloc="/usr/bin"
#
sudo ${exeloc}/qemu-system-x86_64 \
     -enable-kvm \
     -cpu host -smp ${numsmp} \
     -m ${memsize} -drive file=${imgloc}/${imgfile},format=qcow2 \
     -boot c \
     -vnc :95 \
     <b>-netdev type=tap,script=${HOME}/etc/ovs-ifup,downscript=${HOME}/etc/ovs-ifdown,id=hostnet10 \</b>
     -device virtio-net-pci,romfile=,netdev=hostnet10,mac=00:71:50:00:01:51 \
     -localtime
$
$ ./runQemu-on-ovs-network.sh &
...
$
</pre>
อันดับถัดไปให้เข้าใช้ vm ทาง console และกำหนดค่า IP ของ ens3 interface ให้เป็น 10.90.0.11
<pre>
vm$ sudo nano /etc/network/interfaces
vm$ cat /etc/network/interfaces
...
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback

auto ens3
iface ens3 inet static
address 10.90.0.11
netmask 255.255.255.0
network 10.90.0.0
gateway 10.90.0.1
dns-nameservers 8.8.8.8
...
vm$
</pre>
ก็จะได้ VM และ network ดังภาพที่ 5

<p><p>
  <img src="documents/qemuOVSlocalbr2.PNG"> <br>
ภาพที่ 6
<p><p>
หลังจากนั้น เราจะทำให้ host เป็น SNAT gateway ด้วย IP MASQURADE 
<pre>
$ sudo nano /etc/rc.local
$ sudo chmod +x /etc/rc.local
$ cat /etc/rc.local
#!/bin/bash
sudo iptables -t nat -A POSTROUTING -o br0 -j MASQUERADE
sudo iptables -A FORWARD -i br0 -o gw1 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i gw1 -o br0 -j ACCEPT
exit 0
$ 
</pre>
vm ก็จะออก network ได้
<p><p>
<a id="part6"><h2>6. การ openvswitch virtual network</h2></a>
<p><p>
<a href="http://sciencecloud-community.cs.tu.ac.th/?p=492">การสร้าง openvswitch tunneling network</a>
<p><p>
<a id="part1"><h2>7. กำหนดให้ ubuntu 16.04 host สนับสนุนการทำงานแบบ nested virtualization</h2></a>
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
