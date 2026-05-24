import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'menu_model.dart';
import 'review_section.dart';
import 'chat_page.dart';

class MenuDetailPage extends StatefulWidget {
  final MenuModel menu;

  const MenuDetailPage({super.key, required this.menu});

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  bool isFavorite = false;
  String? favoriteDocId;

  @override
  void initState() {
    super.initState();
    checkFavorite();
  }

  Future<void> checkFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .where('menuId', isEqualTo: widget.menu.id)
        .get();

    if (snapshot.docs.isNotEmpty && mounted) {
      setState(() {
        isFavorite = true;
        favoriteDocId = snapshot.docs.first.id;
      });
    }
  }

  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (isFavorite && favoriteDocId != null) {
      await FirebaseFirestore.instance.collection('favorites').doc(favoriteDocId).delete();
      if (mounted) setState(() { isFavorite = false; favoriteDocId = null; });
    } else {
      final doc = await FirebaseFirestore.instance.collection('favorites').add({
        'userId': user.uid,
        'menuId': widget.menu.id,
        'createdAt': Timestamp.now(),
      });
      if (mounted) setState(() { isFavorite = true; favoriteDocId = doc.id; });
    }
  }

  // 🌟 เพิ่มฟังก์ชันสำหรับแชร์ลงหน้าชุมชน
  Future<void> _shareToCommunity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อแชร์เมนู')));
      return;
    }

    final TextEditingController captionController = TextEditingController();
    bool isSharing = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.share, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('แชร์ลงชุมชน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'เขียนแคปชันบอกเพื่อนๆ หน่อย...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                maxLines: 3,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSharing ? null : () async {
                    setStateDialog(() => isSharing = true);
                    try {
                      // บันทึกโพสต์ลง Firestore Collection 'community_posts'
                      await FirebaseFirestore.instance.collection('community_posts').add({
                        'menuId': widget.menu.id,
                        'userId': user.uid,
                        'userEmail': user.email ?? 'ไม่ระบุตัวตน',
                        'caption': captionController.text.trim(),
                        'likes': [], // เริ่มต้นไม่มีคนไลก์
                        'createdAt': Timestamp.now(),
                      });
                      if (!mounted) return;
                      Navigator.pop(dialogContext); // ปิดหน้าต่าง Popup
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('แชร์เมนูลงชุมชนสำเร็จ!'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      setStateDialog(() => isSharing = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
                    }
                  },
                  child: isSharing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('แชร์เลย', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget buildInfoCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('รายละเอียดเมนู'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // 🌟 เพิ่มปุ่มแชร์ไว้ตรงนี้ (ข้างๆ ปุ่มหัวใจ)
          IconButton(
            onPressed: _shareToCommunity,
            icon: const Icon(Icons.ios_share, color: Colors.blue),
          ),
          IconButton(
            onPressed: toggleFavorite,
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
          ),
        ],
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: menu.imageUrl.isNotEmpty
                ? Image.network(menu.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 80)))
                : Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 80)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Text(menu.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
                    
                    if (currentUserEmail != null && currentUserEmail != menu.authorEmail)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(targetEmail: menu.authorEmail)));
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white),
                        label: const Text('ทักแชท', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 0,
                        ),
                      )
                  ],
                ),
                
                const SizedBox(height: 6),
                Text('โดย: ${menu.authorEmail}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 12),
                
                Text(menu.description, style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.5)),
                const Divider(height: 40),
                
                buildSectionTitle('ข้อมูลโภชนาการ'),
                buildInfoCard(title: 'พลังงาน', value: '${menu.calories} kcal', icon: Icons.local_fire_department, color: Colors.orange),
                buildInfoCard(title: 'โปรตีน', value: '${menu.protein} g', icon: Icons.fitness_center, color: Colors.blue),
                
                buildSectionTitle('ส่วนผสมและวัตถุดิบ'),
                ...menu.ingredients.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const Icon(Icons.check_circle, size: 18, color: Colors.teal),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 15))),
                  ]),
                )),
                
                buildSectionTitle('ขั้นตอนการทำ'),
                ...menu.steps.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 10, backgroundColor: Colors.green, child: Text('${entry.key + 1}', style: const TextStyle(fontSize: 12, color: Colors.white))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 15))),
                    ],
                  ),
                )),
                
                const SizedBox(height: 20),
                ReviewSection(menuId: menu.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}