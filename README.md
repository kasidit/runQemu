<a href="https://github.com/kasidit/runQemu/wiki"><h1>Tutorial: การใช้งาน QEMU-KVM เบื้องต้น (บน Ubuntu 20.04)</h1></a>
<ol>
 <li><a href="https://github.com/kasidit/runQemu/wiki">Home</a>
 <li><a href="https://github.com/kasidit/runQemu/wiki/1.-%E0%B8%81%E0%B8%B2%E0%B8%A3%E0%B8%95%E0%B8%B4%E0%B8%94%E0%B8%95%E0%B8%B1%E0%B9%89%E0%B8%87%E0%B8%84%E0%B8%B4%E0%B8%A7%E0%B8%AD%E0%B8%B5%E0%B8%A1%E0%B8%B9">การติดตั้งคิวอีมู</a>
 <li><a href="https://github.com/kasidit/runQemu/wiki/2.-%E0%B8%AA%E0%B8%A3%E0%B9%89%E0%B8%B2%E0%B8%87%E0%B8%AE%E0%B8%B2%E0%B8%A3%E0%B9%8C%E0%B8%94%E0%B8%94%E0%B8%B4%E0%B8%AA%E0%B8%84%E0%B9%8C%E0%B8%AD%E0%B8%B4%E0%B8%A1%E0%B9%80%E0%B8%A1%E0%B8%88%E0%B9%81%E0%B8%9A%E0%B8%9A%E0%B9%80%E0%B8%AA%E0%B8%A1%E0%B8%B7%E0%B8%AD%E0%B8%99%E0%B8%94%E0%B9%89%E0%B8%A7%E0%B8%A2%E0%B8%84%E0%B8%B3%E0%B8%AA%E0%B8%B1%E0%B9%88%E0%B8%87-qemu-img">สร้างฮาร์ดดิสค์อิมเมจแบบเสมือนด้วยคำสั่ง qemu img</a>
 <li><a href="https://github.com/kasidit/runQemu/wiki/3.-%E0%B8%81%E0%B8%B2%E0%B8%A3%E0%B8%95%E0%B8%B4%E0%B8%94%E0%B8%95%E0%B8%B1%E0%B9%89%E0%B8%87%E0%B9%80%E0%B8%81%E0%B8%AA%E0%B8%97%E0%B9%8C%E0%B9%82%E0%B8%AD%E0%B9%80%E0%B8%AD%E0%B8%AA%E0%B8%9A%E0%B8%99%E0%B8%AE%E0%B8%B2%E0%B8%A3%E0%B9%8C%E0%B8%94%E0%B8%94%E0%B8%B4%E0%B8%AA%E0%B8%84%E0%B9%8C%E0%B9%80%E0%B8%AA%E0%B8%A1%E0%B8%B7%E0%B8%AD%E0%B8%99">การติดตั้งเกสท์โอเอสบนฮาร์ดดิสค์เสมือน</a>
 <li><a href="https://github.com/kasidit/runQemu/wiki/4.-%E0%B8%81%E0%B8%B2%E0%B8%A3%E0%B8%9B%E0%B8%A3%E0%B8%B0%E0%B8%A1%E0%B8%A7%E0%B8%A5%E0%B8%9C%E0%B8%A5%E0%B8%A7%E0%B8%B5%E0%B9%80%E0%B8%AD%E0%B9%87%E0%B8%A1%E0%B9%81%E0%B8%A5%E0%B8%B0%E0%B9%83%E0%B8%8A%E0%B9%89%E0%B8%A3%E0%B8%B0%E0%B8%9A%E0%B8%9A%E0%B9%80%E0%B8%84%E0%B8%A3%E0%B8%B7%E0%B8%AD%E0%B8%82%E0%B9%88%E0%B8%B2%E0%B8%A2%E0%B9%81%E0%B8%9A%E0%B8%9A-NAT-%E0%B9%80%E0%B8%89%E0%B8%9E%E0%B8%B2%E0%B8%B0%E0%B9%80%E0%B8%84%E0%B8%A3%E0%B8%B7%E0%B9%88%E0%B8%AD%E0%B8%87">การประมวลผลวีเอ็มและใช้ระบบเครือข่ายแบบ NAT เฉพาะเครื่อง</a>
 <li><a href="https://github.com/kasidit/runQemu/wiki/5.-%E0%B8%81%E0%B8%B2%E0%B8%A3%E0%B8%AA%E0%B8%A3%E0%B9%89%E0%B8%B2%E0%B8%87%E0%B8%94%E0%B8%B4%E0%B8%AA%E0%B8%84%E0%B9%8C%E0%B8%AD%E0%B8%B4%E0%B8%A1%E0%B9%80%E0%B8%A1%E0%B8%88%E0%B9%81%E0%B8%9A%E0%B8%9A-qcow2-overlay">การสร้างดิสค์อิมเมจแบบ qcow2 overlay</a>
 <li><a href="https://github.com/kasidit/runQemu/wiki/6.-%E0%B8%81%E0%B8%B2%E0%B8%A3%E0%B9%80%E0%B8%8A%E0%B8%B7%E0%B9%88%E0%B8%AD%E0%B8%A1%E0%B8%95%E0%B9%88%E0%B8%AD-%E0%B8%84%E0%B8%B4%E0%B8%A7%E0%B8%AD%E0%B8%B5%E0%B8%A1%E0%B8%B9-%E0%B9%80%E0%B8%82%E0%B9%89%E0%B8%B2%E0%B8%81%E0%B8%B1%E0%B8%9A-L2-Network-%E0%B8%94%E0%B9%89%E0%B8%A7%E0%B8%A2%E0%B8%A5%E0%B8%B4%E0%B8%99%E0%B8%B8%E0%B8%81%E0%B8%8B%E0%B9%8C%E0%B8%9A%E0%B8%A3%E0%B8%B4%E0%B8%94%E0%B8%88%E0%B9%8C">การเชื่อมต่อ คิวอีมู เข้ากับ L2 Network ด้วยลินุกซ์บริดจ์</a>
 <li><a href="https://github.com/kasidit/runQemu/wiki/7.--%E0%B8%81%E0%B8%B2%E0%B8%A3%E0%B8%AA%E0%B8%A3%E0%B9%89%E0%B8%B2%E0%B8%87%E0%B8%A7%E0%B8%B5%E0%B9%80%E0%B8%AD%E0%B9%87%E0%B8%A1%E0%B9%82%E0%B8%94%E0%B8%A2%E0%B9%83%E0%B8%8A%E0%B9%89%E0%B8%AD%E0%B8%B4%E0%B8%A1%E0%B9%80%E0%B8%A1%E0%B8%88%E0%B8%97%E0%B8%B5%E0%B9%88%E0%B8%81%E0%B8%B3%E0%B8%AB%E0%B8%99%E0%B8%94%E0%B8%84%E0%B9%88%E0%B8%B2%E0%B8%94%E0%B9%89%E0%B8%A7%E0%B8%A2%E0%B8%A3%E0%B8%B0%E0%B8%9A%E0%B8%9A%E0%B8%84%E0%B8%A5%E0%B8%B2%E0%B8%A7%E0%B8%94%E0%B9%8C%E0%B8%AD%E0%B8%B4%E0%B8%99%E0%B8%99%E0%B8%B4%E0%B8%95-(cloud-init)">การสร้างวีเอ็มโดยใช้อิมเมจที่กำหนดค่าด้วยระบบคลาวด์อินนิต (cloud init)</a>
</ol>
<p>
<h3>เทคโนโลยีที่เกี่ยวข้อง </h3>
<ol>
<li> <a href="https://github.com/kasidit/container-study/wiki">เรียนรู้โครงสร้างของคอนเทนเนอร์เบื้องต้น</a>
       <ul>
       <li> <a href="https://github.com/kasidit/container-study/wiki/1.-%E0%B9%82%E0%B8%84%E0%B8%A3%E0%B8%87%E0%B8%AA%E0%B8%A3%E0%B9%89%E0%B8%B2%E0%B8%87%E0%B8%82%E0%B8%AD%E0%B8%87%E0%B8%84%E0%B8%AD%E0%B8%99%E0%B9%80%E0%B8%97%E0%B8%99%E0%B9%80%E0%B8%99%E0%B8%AD%E0%B8%A3%E0%B9%8C%E0%B9%80%E0%B8%9A%E0%B8%B7%E0%B9%89%E0%B8%AD%E0%B8%87%E0%B8%95%E0%B9%89%E0%B8%99">โครงสร้างของคอนเทนเนอร์เบื้องต้น</a>
       <li> <a href="https://github.com/kasidit/container-study/wiki/2.-%E0%B8%97%E0%B8%94%E0%B8%A5%E0%B8%AD%E0%B8%87%E0%B8%AA%E0%B8%A3%E0%B9%89%E0%B8%B2%E0%B8%87%E0%B8%84%E0%B8%AD%E0%B8%99%E0%B9%80%E0%B8%97%E0%B8%99%E0%B9%80%E0%B8%99%E0%B8%AD%E0%B8%A3%E0%B9%8C%E0%B8%94%E0%B9%89%E0%B8%A7%E0%B8%A2%E0%B8%95%E0%B8%99%E0%B9%80%E0%B8%AD%E0%B8%87">ทดลองสร้างคอนเทนเนอร์ด้วยตนเอง</a>
       </ul>
 <li> <a href="https://github.com/kasidit/openstack-victoria-basic-installer">การติดตั้งระบบ OpenStack (Victoria)</a>
</ol>
