import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'menu_model.dart';
import 'add_menu_page.dart';
import 'profile_page.dart';
import 'recommend_page.dart';
import 'menu_detail_page.dart';
import 'favorite_page.dart';
import 'search_page.dart';
import 'community_page.dart';
import 'trending_posts_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    MenuListSection(),
    SearchPage(),
    RecommendPage(),
    CommunityPage(),
  ];

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('เมนูสุขภาพ', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_fire_department, color: Colors.orange),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TrendingPostsPage())),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritePage())),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMenuPage()));
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('เพิ่มเมนู', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'ค้นหา'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'แนะนำ'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'ชุมชน'),
        ],
      ),
    );
  }
}

class MenuListSection extends StatelessWidget {
  const MenuListSection({super.key});

  Stream<List<MenuModel>> getMenus() {
    return FirebaseFirestore.instance
        .collection('menus')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MenuModel.fromMap(doc.id, doc.data())).toList());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MenuModel>>(
      stream: getMenus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        
        final menus = snapshot.data ?? [];
        if (menus.isEmpty) return const Center(child: Text('ยังไม่มีเมนูอาหาร'));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: menus.length,
          itemBuilder: (context, index) {
            final menu = menus[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  // แก้ไขตรงนี้ให้ส่ง menu ไปอย่างถูกต้อง
                  MaterialPageRoute(builder: (context) => MenuDetailPage(menu: menu)),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.06), offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: SizedBox(
                        height: 180, width: double.infinity,
                        child: (menu.imageUrl.isNotEmpty && menu.imageUrl.startsWith('http'))
                            ? Image.network(menu.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 60)))
                            : Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 60)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(menu.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(menu.category, style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(menu.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}