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
        title: const Text('โพสต์ยอดฮิต 🔥', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('community_posts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('ยังไม่มีโพสต์ให้จัดอันดับ'));

          // 1. นำข้อมูลมานับยอด Like และจัดเรียง
          List<Map<String, dynamic>> trendingList = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final List<dynamic> likes = data['likes'] ?? [];
            return {'id': doc.id, 'likeCount': likes.length, ...data};
          }).toList();

          trendingList.sort((a, b) => b['likeCount'].compareTo(a['likeCount']));
          // กรองเอาเฉพาะที่มีคน Like (ถ้าต้องการ)
          trendingList = trendingList.where((item) => item['likeCount'] > 0).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trendingList.length,
            itemBuilder: (context, index) {
              final post = trendingList[index];
              final String menuId = post['menuId'] ?? '';
              final String username = (post['userEmail'] ?? 'User').toString().split('@')[0];

              // 🌟 ใช้ FutureBuilder เพื่อไปดึงรูปภาพและข้อมูลจาก Collection 'menus'
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('menus').doc(menuId).get(),
                builder: (context, menuSnapshot) {
                  if (!menuSnapshot.hasData || !menuSnapshot.data!.exists) return const SizedBox();

                  final menuData = menuSnapshot.data!.data() as Map<String, dynamic>;
                  final menu = MenuModel.fromMap(menuSnapshot.data!.id, menuData);

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
                          // 🖼 ส่วนแสดงรูปภาพขนาดใหญ่
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: Image.network(
                                  menu.imageUrl,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(height: 180, color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 50)),
                                ),
                              ),
                              // ป้ายอันดับ
                              Positioned(top: 12, left: 12, child: _buildRankBadge(index)),
                              // ป้ายยอด Like
                              Positioned(
                                top: 12, right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                                      const SizedBox(width: 4),
                                      Text('${post['likeCount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // ข้อมูลรายละเอียด
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(menu.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('โดย: $username', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                const SizedBox(height: 8),
                                Text(post['caption'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
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