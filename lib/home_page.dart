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
import 'chat_list_page.dart'; 

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
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListPage())),
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

// 🌟 เปลี่ยนจาก StatelessWidget เป็น StatefulWidget เพื่อให้รองรับการรีเฟรชหน้าจอ
class MenuListSection extends StatefulWidget {
  const MenuListSection({super.key});

  @override
  State<MenuListSection> createState() => _MenuListSectionState();
}

class _MenuListSectionState extends State<MenuListSection> {
  late Stream<List<MenuModel>> _menuStream;

  @override
  void initState() {
    super.initState();
    _menuStream = _getMenus();
  }

  Stream<List<MenuModel>> _getMenus() {
    return FirebaseFirestore.instance
        .collection('menus')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>; 
            final status = data['status']?.toString().toLowerCase() ?? 'published'; 
            return status != 'deleted'; 
          }).map((doc) {
            return MenuModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();
        });
  }

  // 🌟 ฟังก์ชันสำหรับดึงหน้าจอลงเพื่อรีเฟรช (Pull to Refresh)
  Future<void> _handleRefresh() async {
    // หน่วงเวลาเล็กน้อยให้ผู้ใช้เห็นแอนิเมชันหมุนๆ
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _menuStream = _getMenus(); // รีเซ็ตการดึงข้อมูลใหม่
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Colors.green, // สีของตัวหมุนโหลด
      backgroundColor: Colors.white,
      child: StreamBuilder<List<MenuModel>>(
        stream: _menuStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          
          final menus = snapshot.data ?? [];
          
          // ถ้าไม่มีเมนู ให้แสดงข้อความเปล่าๆ (แต่ยังต้องดึงหน้าจอรีเฟรชได้)
          if (menus.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(child: Text('ยังไม่มีเมนูอาหาร')),
              ],
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // 🌟 จำเป็นต้องใส่เพื่อให้ดึงหน้าจอลงได้เสมอแม้ข้อมูลจะน้อย
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. กล่องแนะนำเมนูตามโรค
                const DiseaseRecommendedMenus(),
                
                const SizedBox(height: 10),
                const Text('เมนูอาหารทั้งหมด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // 2. รายการเมนูทั้งหมด
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(), 
                  shrinkWrap: true, 
                  itemCount: menus.length,
                  itemBuilder: (context, index) {
                    final menu = menus[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =========================================================================
// วิดเจ็ต: สำหรับดึงและแสดง "เมนูที่ปลอดภัยตามโรคของผู้ใช้"
// =========================================================================
class DiseaseRecommendedMenus extends StatelessWidget {
  const DiseaseRecommendedMenus({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final userDisease = userData['disease']?.toString() ?? '';

        if (userDisease.isEmpty || userDisease == 'ไม่มี') {
          return const SizedBox.shrink();
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('diseases').get(),
          builder: (context, diseaseSnapshot) {
            if (!diseaseSnapshot.hasData) return const SizedBox.shrink();

            Map<String, dynamic>? targetRules;
            String matchedDiseaseName = '';

            for (var doc in diseaseSnapshot.data!.docs) {
              final diseaseName = doc['name'].toString();
              final cleanUserDisease = userDisease.replaceAll('โรค', '').trim().toLowerCase();
              final cleanDbDisease = diseaseName.replaceAll('โรค', '').trim().toLowerCase();

              if (cleanUserDisease.isNotEmpty && cleanDbDisease.isNotEmpty &&
                  (cleanUserDisease.contains(cleanDbDisease) || cleanDbDisease.contains(cleanUserDisease))) {
                targetRules = doc['rules'] as Map<String, dynamic>?;
                matchedDiseaseName = diseaseName;
                break;
              }
            }

            if (targetRules == null || matchedDiseaseName.isEmpty) return const SizedBox.shrink();

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('menus').snapshots(),
              builder: (context, menuSnapshot) {
                if (menuSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final menusDocs = menuSnapshot.data?.docs ?? [];
                List<MenuModel> safeMenus = [];

                for (var doc in menusDocs) {
                  final menuData = doc.data() as Map<String, dynamic>;
                  final menu = MenuModel.fromMap(doc.id, menuData);
                  bool isSafe = true;

                  if (targetRules!['sodium'] != null && menu.sodium > targetRules['sodium']) isSafe = false;
                  if (targetRules['sugar'] != null && menu.carb > targetRules['sugar']) isSafe = false;
                  if (targetRules['fat'] != null && menu.fat > targetRules['fat']) isSafe = false;
                  if (targetRules['protein'] != null && menu.protein > targetRules['protein']) isSafe = false;
                  if (targetRules['calories'] != null && menu.calories > targetRules['calories']) isSafe = false;

                  if (isSafe && menuData['status'] != 'deleted') {
                    safeMenus.add(menu);
                  }
                }

                if (safeMenus.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.health_and_safety, color: Colors.green, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'เมนูปลอดภัยสำหรับผู้ป่วย $matchedDiseaseName',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 190,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: safeMenus.length,
                        itemBuilder: (context, index) {
                          final menu = safeMenus[index];
                          return Container(
                            width: 150, 
                            margin: const EdgeInsets.only(right: 12, bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black.withOpacity(0.05), offset: const Offset(0, 2))],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MenuDetailPage(menu: menu))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: (menu.imageUrl.isNotEmpty && menu.imageUrl.startsWith('http'))
                                        ? Image.network(menu.imageUrl, height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 100, color: Colors.grey.shade200, child: const Icon(Icons.fastfood)))
                                        : Container(height: 100, color: Colors.grey.shade200, child: const Icon(Icons.fastfood)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(menu.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text('${menu.calories} kcal', style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 30, thickness: 1), 
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}