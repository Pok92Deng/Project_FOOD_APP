import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_model.dart';
import 'menu_detail_page.dart';

class TrendingPostsPage extends StatelessWidget {
  const TrendingPostsPage({super.key});

  // ฟังก์ชันสร้างสัญลักษณ์อันดับ (เหรียญทอง, เงิน, ทองแดง)
  Widget _buildRankBadge(int index) {
    if (index == 0) return const CircleAvatar(backgroundColor: Color(0xFFFFD700), radius: 15, child: Icon(Icons.emoji_events, color: Colors.white, size: 18));
    if (index == 1) return const CircleAvatar(backgroundColor: Color(0xFFC0C0C0), radius: 15, child: Icon(Icons.emoji_events, color: Colors.white, size: 18));
    if (index == 2) return const CircleAvatar(backgroundColor: Color(0xFFCD7F32), radius: 15, child: Icon(Icons.emoji_events, color: Colors.white, size: 18));
    return CircleAvatar(backgroundColor: Colors.grey.shade200, radius: 15, child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('เมนูยอดฮิต 🔥', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      
      // 🌟 ใช้ StreamBuilder ดึงทั้ง โพสต์ และ เมนู มาประมวลผลพร้อมกัน
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('community_posts').snapshots(),
        builder: (context, postSnapshot) {
          if (postSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final postsDocs = postSnapshot.data?.docs ?? [];
          if (postsDocs.isEmpty) return const Center(child: Text('ยังไม่มีการแชร์เมนูในชุมชน'));

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('menus').snapshots(),
            builder: (context, menuSnapshot) {
              if (menuSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final menusDocs = menuSnapshot.data?.docs ?? [];
              
              // 🌟 1. จัดกลุ่มโพสต์ตามเมนู (Group by Menu) และ "รวมยอด Like"
              Map<String, Map<String, dynamic>> groupedMenus = {};

              for (var postDoc in postsDocs) {
                final postData = postDoc.data() as Map<String, dynamic>;
                final String menuId = postData['menuId']?.toString() ?? '';
                final List<dynamic> likes = postData['likes'] ?? [];
                
                if (menuId.isEmpty) continue;

                if (groupedMenus.containsKey(menuId)) {
                  // ถ้ามีเมนูนี้ในกลุ่มแล้ว ให้ "บวก" ยอด Like เพิ่มเข้าไป
                  groupedMenus[menuId]!['totalLikes'] += likes.length;
                } else {
                  // ถ้ายังไม่มี ให้สร้างรายการใหม่ (เก็บชื่อคนโพสต์คนแรกไว้แสดงผล)
                  groupedMenus[menuId] = {
                    'menuId': menuId,
                    'totalLikes': likes.length,
                    'userEmail': postData['userEmail'] ?? 'User',
                    'caption': postData['caption'] ?? '',
                  };
                }
              }

              // 🌟 2. ตรวจสอบว่าเมนูนั้นยังไม่ถูกแอดมินลบทิ้งไป
              List<Map<String, dynamic>> validRanking = [];
              for (var entry in groupedMenus.values) {
                final menuId = entry['menuId'];
                final menuExist = menusDocs.where((m) => m.id == menuId).toList();
                
                if (menuExist.isNotEmpty) {
                  final menuData = menuExist.first.data() as Map<String, dynamic>;
                  entry['menuData'] = menuData; // เอาข้อมูลเมนูจริงมาแปะไว้เตรียมแสดงผล
                  validRanking.add(entry);
                }
              }

              // 🌟 3. เรียงลำดับตามยอด Like รวม (จากมากไปน้อย)
              validRanking.sort((a, b) => b['totalLikes'].compareTo(a['totalLikes']));
              
              // กรองเอาเฉพาะอันที่มียอดไลก์มากกว่า 0
              validRanking = validRanking.where((item) => item['totalLikes'] > 0).toList();

              if (validRanking.isEmpty) return const Center(child: Text('ยังไม่มีเมนูที่ถูกใจ ให้อันดับ'));

              // 🌟 4. วาด UI
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: validRanking.length,
                itemBuilder: (context, index) {
                  final item = validRanking[index];
                  final String username = (item['userEmail']).toString().split('@')[0];
                  final int totalLikes = item['totalLikes'];
                  
                  // สร้าง MenuModel
                  final menu = MenuModel.fromMap(item['menuId'], item['menuData']);

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: index < 3 ? 4 : 1,
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MenuDetailPage(menu: menu))),
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: Image.network(
                                  menu.imageUrl,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(height: 180, width: double.infinity, color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 50, color: Colors.grey)),
                                ),
                              ),
                              Positioned(top: 12, left: 12, child: _buildRankBadge(index)),
                              Positioned(
                                top: 12, right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                                      const SizedBox(width: 4),
                                      Text('$totalLikes', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(menu.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('นำเทรนด์โดย: $username', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                const SizedBox(height: 8),
                                Text(item['caption'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
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
        },
      ),
    );
  }
}