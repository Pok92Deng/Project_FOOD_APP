import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_model.dart';
import 'menu_detail_page.dart';
import 'edit_menu_page.dart';
import 'edit_profile_page.dart'; // 🌟 เปลี่ยนมาดึงหน้า EditProfilePage แทน

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 🌟 ฟังก์ชันลบเมนู
  Future<void> _deleteMenu(String menuId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบเมนูอาหารนี้ออกจากระบบ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ลบเมนู', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('menus').doc(menuId).delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบเมนูอาหารสำเร็จแล้ว')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('โปรไฟล์ของฉัน', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🌟 ส่วนดึงข้อมูลโปรไฟล์จากตาราง 'users'
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
            builder: (context, snapshot) {
              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final displayName = userData?['displayName'] ?? user?.email?.split('@')[0] ?? 'User';

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.green.shade100,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(user?.email ?? '', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    
                    const SizedBox(height: 10),
                    // โชว์ข้อมูลเพิ่มเติม
                    Text('โรคประจำตัว: ${userData?['disease'] ?? 'ไม่มี'} | นน: ${userData?['weight'] ?? 0} กก.', 
                         style: const TextStyle(fontSize: 12, color: Colors.green)),
                         
                    const SizedBox(height: 15),
                    
                    // 🌟 ปุ่มกดเปิดหน้า EditProfilePage
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('จัดการข้อมูลส่วนตัว'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        // 🌟 วิ่งไปที่หน้ากรอกข้อมูลที่เราเพิ่งสร้าง
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfilePage()),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.restaurant_menu, size: 20, color: Colors.green),
                SizedBox(width: 8),
                Text('เมนูอาหารที่ฉันสร้าง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('menus')
                  .where('authorEmail', isEqualTo: user?.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลเมนู'));
                }
                
                final docs = snapshot.data?.docs ?? [];
                final myMenus = docs.map((doc) => 
                  MenuModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();

                if (myMenus.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers_clear, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('คุณยังไม่ได้สร้างเมนูใดๆ', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: myMenus.length,
                  itemBuilder: (context, index) {
                    final menu = myMenus[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: menu.imageUrl.isNotEmpty && menu.imageUrl.startsWith('http')
                              ? Image.network(
                                  menu.imageUrl, 
                                  width: 55, 
                                  height: 55, 
                                  fit: BoxFit.cover, 
                                  errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, width: 55, height: 55, child: const Icon(Icons.fastfood))
                                )
                              : Container(color: Colors.grey.shade200, width: 55, height: 55, child: const Icon(Icons.fastfood)),
                        ),
                        title: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('${menu.category} • ${menu.calories} kcal', style: TextStyle(color: Colors.green.shade700)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange), 
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => EditMenuPage(menu: menu)));
                              }
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent), 
                              onPressed: () => _deleteMenu(menu.id)
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => MenuDetailPage(menu: menu)));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}