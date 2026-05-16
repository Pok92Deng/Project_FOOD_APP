import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'menu_model.dart';
import 'review_section.dart';

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

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('รายละเอียดเมนู'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
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
                ? Image.network(menu.imageUrl, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 80)))
                : Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 80)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(menu.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
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
                    Text(item, style: const TextStyle(fontSize: 15)),
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