import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  Future<void> _toggleLike(String postId, List<dynamic> currentLikes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = FirebaseFirestore.instance.collection('community_posts').doc(postId);
    
    if (currentLikes.contains(user.uid)) {
      // ถ้ายกเลิกไลก์
      await postRef.update({
        'likes': FieldValue.arrayRemove([user.uid])
      });
    } else {
      // ถ้ากดไลก์
      await postRef.update({
        'likes': FieldValue.arrayUnion([user.uid])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('ชุมชนคนรักสุขภาพ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ดึงข้อมูลโพสต์เรียงตามเวลาล่าสุด
        stream: FirebaseFirestore.instance.collection('community_posts').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          }

          final posts = snapshot.data?.docs ?? [];

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('ยังไม่มีโพสต์ในชุมชน\nกดแชร์เมนูเพื่อเริ่มพูดคุยกันสิ!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final postDoc = posts[index];
              final post = postDoc.data() as Map<String, dynamic>;
              
              // ดึงคนกดไลก์ (ถ้าไม่มีให้เป็น List ว่าง)
              final List<dynamic> likes = post['likes'] ?? [];
              final bool isLiked = currentUser != null && likes.contains(currentUser.uid);
              final String userEmail = post['userEmail'] ?? 'ผู้ใช้ทั่วไป';
              final String username = userEmail.split('@')[0];

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ส่วนหัว: ชื่อคนโพสต์
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Text(username[0].toUpperCase(), style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('แชร์สูตรอาหารเข้าชุมชน', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // ส่วนแคปชัน
                      if (post['caption'] != null && post['caption'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(post['caption'], style: const TextStyle(fontSize: 15, height: 1.4)),
                        ),
                      
                      // กล่องแสดงเมนูที่แชร์มา (สมมติว่าเป็นไอคอนชามอาหาร)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade100)),
                        child: Row(
                          children: [
                            Icon(Icons.restaurant_menu, color: Colors.orange.shade400, size: 30),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('ดูรายละเอียดเมนูอาหารนี้', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade500),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      
                      // ปุ่ม Like และ Comment
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: () => _toggleLike(postDoc.id, likes),
                            icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey),
                            label: Text('${likes.length} ถูกใจ', style: TextStyle(color: isLiked ? Colors.red : Colors.grey.shade700)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ฟีเจอร์คอมเมนต์กำลังมาในเร็วๆ นี้!')));
                            },
                            icon: Icon(Icons.chat_bubble_outline, color: Colors.grey.shade700),
                            label: Text('ความคิดเห็น', style: TextStyle(color: Colors.grey.shade700)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}