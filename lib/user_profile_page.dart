import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_detail_page.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;
  final String userEmail;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          // 🛠️ แก้ไข 1: ดึงแค่ where เพื่อไม่ให้ Firebase ฟ้องเรื่อง Index
          stream: FirebaseFirestore.instance
              .collection('community_posts')
              .where('userId', isEqualTo: userId)
              .snapshots(),
          builder: (context, postSnapshot) {
            // 🛠️ แก้ไข 2: เพิ่มการเช็ค Error ถ้าพังจะได้โชว์ตัวหนังสือแทนการหมุนค้าง
            if (postSnapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาด: ${postSnapshot.error}'));
            }
            if (postSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var posts = postSnapshot.data?.docs.toList() ?? [];

            // 🛠️ แก้ไข 3: นำข้อมูลมาจัดเรียงเวลาจากใหม่ไปเก่าในเครื่องแทน
            posts.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['createdAt'] as Timestamp?;
              final bTime = bData['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime); // ใหม่สุดขึ้นก่อน
            });

            // 🛠️ แก้ไข 4: คำนวณยอดไลก์รวมให้ถูกต้อง (นับจากโพสต์ทั้งหมดของคนนี้)
            int totalLikes = 0;
            for (var postDoc in posts) {
              final data = postDoc.data() as Map<String, dynamic>;
              final likes = data['likes'] is List ? List.from(data['likes']) : [];
              totalLikes += likes.length;
            }

            return Column(
              children: [
                // 🔥 Header Profile
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF9F43), Color(0xFFFF6B6B)],
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 👤 Avatar
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: Text(
                          userEmail.isNotEmpty && userEmail != 'ผู้ใช้ทั่วไป' ? userEmail[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        userEmail.split('@')[0], // โชว์แค่ชื่อหน้า @ ให้สวยงาม
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 📊 Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildStatItem(
                            title: 'โพสต์',
                            value: posts.length.toString(),
                          ),
                          buildStatItem(
                            title: 'ถูกใจรวม',
                            value: totalLikes.toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'โพสต์ของสมาชิก',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 📄 List Posts
                Expanded(
                  child: posts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.speaker_notes_off, size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('ผู้ใช้รายนี้ยังไม่มีการโพสต์ใดๆ', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final postDoc = posts[index];
                            final postData = postDoc.data() as Map<String, dynamic>;
                            final menuId = (postData['menuId'] ?? '').toString();

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('menus').doc(menuId).get(),
                              builder: (context, menuSnapshot) {
                                if (!menuSnapshot.hasData || !menuSnapshot.data!.exists) {
                                  // ถ้าหาเมนูไม่เจอ (อาจจะถูกลบไปแล้ว) ไม่ต้องแสดงการ์ดใบนี้
                                  return const SizedBox();
                                }

                                final menuData = menuSnapshot.data!.data() as Map<String, dynamic>;
                                final imageUrl = (menuData['imageUrl'] ?? '').toString();

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CommunityDetailPage(
                                          postId: postDoc.id,
                                          postData: postData,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 10,
                                          color: Colors.black.withOpacity(0.05),
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 🖼 รูปอาหาร
                                        if (imageUrl.isNotEmpty && imageUrl.startsWith('http'))
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                            child: Image.network(
                                              imageUrl,
                                              height: 180,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  height: 180,
                                                  color: Colors.grey.shade200,
                                                  child: const Center(child: Icon(Icons.fastfood, size: 60)),
                                                );
                                              },
                                            ),
                                          )
                                        else
                                          Container(
                                            height: 180,
                                            color: Colors.grey.shade200,
                                            child: const Center(child: Icon(Icons.fastfood, size: 60)),
                                          ),

                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (menuData['name'] ?? '').toString(),
                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                (postData['caption'] ?? '').toString(),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: Colors.grey.shade700),
                                              ),
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
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildStatItem({required String title, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}