import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'review_section.dart';

class MenuDetailPage extends StatefulWidget {
  final Map<String, dynamic> menuData;
  final String menuId;

  const MenuDetailPage({
    super.key,
    required this.menuData,
    required this.menuId,
  });

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
        .where('menuId', isEqualTo: widget.menuId)
        .get();

    if (snapshot.docs.isNotEmpty) {
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
      await FirebaseFirestore.instance
          .collection('favorites')
          .doc(favoriteDocId)
          .delete();

      setState(() {
        isFavorite = false;
        favoriteDocId = null;
      });
    } else {
      final doc = await FirebaseFirestore.instance.collection('favorites').add({
        'userId': user.uid,
        'menuId': widget.menuId,
        'createdAt': Timestamp.now(),
      });

      setState(() {
        isFavorite = true;
        favoriteDocId = doc.id;
      });
    }
  }

  Future<void> shareToCommunity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final captionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('แชร์เข้าชุมชน'),
          content: TextField(
            controller: captionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'เขียนข้อความประกอบการแชร์...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('แชร์'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance.collection('community_posts').add({
      'menuId': widget.menuId,
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'caption': captionController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('แชร์เข้าชุมชนสำเร็จ')),
    );
  }

  Widget buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (widget.menuData['imageUrl'] ?? '').toString();
    final name = (widget.menuData['name'] ?? '').toString();
    final category = (widget.menuData['category'] ?? '').toString();
    final description = (widget.menuData['description'] ?? '').toString();
    final ingredients = (widget.menuData['ingredients'] ?? '').toString();
    final steps = (widget.menuData['steps'] ?? '').toString();
    final calories = (widget.menuData['calories'] ?? '').toString();
    final protein = (widget.menuData['protein'] ?? '').toString();
    final suitableForDisease =
        (widget.menuData['suitableForDisease'] ?? '').toString();
    final suitableForGoal =
        (widget.menuData['suitableForGoal'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('รายละเอียดเมนู'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: shareToCommunity,
            icon: const Icon(Icons.share),
          ),
          IconButton(
            onPressed: toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 240,
            width: double.infinity,
            child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.fastfood, size: 80),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.fastfood, size: 80),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    category.isEmpty ? 'ไม่ระบุหมวดหมู่' : category,
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description.isEmpty ? 'ไม่มีรายละเอียด' : description,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ข้อมูลสุขภาพ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                buildInfoCard(
                  title: 'เหมาะกับโรค',
                  value: suitableForDisease,
                  icon: Icons.health_and_safety,
                  color: Colors.redAccent,
                ),
                buildInfoCard(
                  title: 'เหมาะกับเป้าหมาย',
                  value: suitableForGoal,
                  icon: Icons.flag,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                const Text(
                  'ข้อมูลโภชนาการ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                buildInfoCard(
                  title: 'พลังงาน',
                  value: calories,
                  icon: Icons.local_fire_department,
                  color: Colors.deepOrange,
                ),
                buildInfoCard(
                  title: 'โปรตีน',
                  value: protein,
                  icon: Icons.fitness_center,
                  color: Colors.blue,
                ),
                const SizedBox(height: 10),
                const Text(
                  'ส่วนผสม',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                buildInfoCard(
                  title: 'วัตถุดิบ',
                  value: ingredients,
                  icon: Icons.shopping_basket,
                  color: Colors.teal,
                ),
                const SizedBox(height: 10),
                const Text(
                  'วิธีทำ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                buildInfoCard(
                  title: 'ขั้นตอนการทำ',
                  value: steps,
                  icon: Icons.menu_book,
                  color: Colors.purple,
                ),
                const SizedBox(height: 24),
                ReviewSection(menuId: widget.menuId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}