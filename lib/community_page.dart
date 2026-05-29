import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_detail_page.dart';
import 'user_profile_page.dart';
import 'menu_model.dart';
import 'menu_detail_page.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  Future<void> _toggleLike(String postId, List<dynamic> currentLikes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = FirebaseFirestore.instance.collection('community_posts').doc(postId);
    
    if (currentLikes.contains(user.uid)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([user.uid])
      });
    } else {
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
                  const Icon(Icons.forum, size: 80, color: Colors.grey),
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
              
              final List<dynamic> likes = post['likes'] is List ? List.from(post['likes']) : [];
              final bool isLiked = currentUser != null && likes.contains(currentUser.uid);
              final String userEmail = post['userEmail']?.toString() ?? 'ผู้ใช้ทั่วไป';
              final String username = userEmail.isNotEmpty && userEmail != 'ผู้ใช้ทั่วไป' ? userEmail.split('@')[0] : 'U';
              final String caption = post['caption']?.toString() ?? '';
              final String postUserId = post['userId']?.toString() ?? ''; 
              final String menuId = post['menuId']?.toString() ?? '';

              // ถ้าไม่มี menuId ให้ข้ามโพสต์นี้ไปเลย
              if (menuId.isEmpty) return const SizedBox.shrink();

              // 🌟 เอา FutureBuilder มาครอบโพสต์ทั้งก้อน (Card)
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('menus').doc(menuId).get(),
                builder: (context, menuSnapshot) {
                  if (menuSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink(); // ซ่อนไว้ก่อนตอนกำลังโหลด
                  }
                  
                  // 🌟 เช็คว่าเมนูถูกลบไปหรือยัง
                  bool isMenuDeleted = !menuSnapshot.hasData || !menuSnapshot.data!.exists;
                  if (!isMenuDeleted) {
                    final data = menuSnapshot.data!.data() as Map<String, dynamic>;
                    final status = data['status']?.toString().toLowerCase() ?? 'published';
                    if (status == 'deleted') isMenuDeleted = true;
                  }

                  // 🚨 ถ้าเมนูถูกลบแล้ว ให้สั่งซ่อนโพสต์ "ทั้งก้อน" ไปเลย (SizedBox.shrink)
                  if (isMenuDeleted) {
                    return const SizedBox.shrink();
                  }

                  // ถ้าเมนูยังอยู่ ก็แปลงข้อมูลแล้วเอามาสร้างโพสต์ตามปกติ
                  final menuData = menuSnapshot.data!.data() as Map<String, dynamic>;
                  final menu = MenuModel.fromMap(menuSnapshot.data!.id, menuData);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              if (postUserId.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfilePage(
                                      userId: postUserId,
                                      userEmail: userEmail,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ไม่พบข้อมูลโปรไฟล์ของผู้ใช้นี้')),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.green.shade100,
                                    child: Text(
                                      username.isNotEmpty ? username[0].toUpperCase() : 'U', 
                                      style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold)
                                    ),
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
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          if (caption.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(caption, style: const TextStyle(fontSize: 15, height: 1.4)),
                            ),
                          
                          // การ์ดเมนูที่ถูกแชร์
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => MenuDetailPage(menu: menu)),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                    child: (menu.imageUrl.isNotEmpty && menu.imageUrl.startsWith('http'))
                                        ? Image.network(
                                            menu.imageUrl,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey.shade200,
                                                child: const Center(child: Icon(Icons.fastfood, size: 40, color: Colors.grey,)),
                                              );
                                            },
                                          )
                                        : Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey.shade200,
                                            child: const Center(child: Icon(Icons.fastfood, size: 40, color: Colors.grey,)),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            menu.name, 
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'หมวดหมู่: ${menu.category} • คลิกเพื่อดูวิธีทำ', 
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ),

                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('community_comments')
                                .where('postId', isEqualTo: postDoc.id)
                                .snapshots(),
                            builder: (context, commentSnapshot) {
                              if (!commentSnapshot.hasData || commentSnapshot.data!.docs.isEmpty) {
                                return const SizedBox(); 
                              }

                              var comments = commentSnapshot.data!.docs.toList();
                              comments.sort((a, b) {
                                final aData = a.data() as Map<String, dynamic>;
                                final bData = b.data() as Map<String, dynamic>;
                                final aTime = aData['createdAt'] as Timestamp?;
                                final bTime = bData['createdAt'] as Timestamp?;
                                if (aTime == null || bTime == null) return 0;
                                return aTime.compareTo(bTime);
                              });

                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 14),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.chat_bubble, size: 13, color: Colors.grey.shade600),
                                        const SizedBox(width: 6),
                                        Text(
                                          'ความคิดเห็น (${comments.length})',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: comments.length > 3 ? 3 : comments.length,
                                      itemBuilder: (context, cIndex) {
                                        final cData = comments[cIndex].data() as Map<String, dynamic>;
                                        final commenterName = (cData['userEmail'] ?? 'User').toString().split('@')[0];
                                        final commentText = cData['comment'] ?? '';

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: RichText(
                                            text: TextSpan(
                                              style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3),
                                              children: [
                                                TextSpan(
                                                  text: '$commenterName: ',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                                ),
                                                TextSpan(text: commentText),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    if (comments.length > 3)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'ดูความคิดเห็นเพิ่มเติมอีก ${comments.length - 3} รายการ...',
                                          style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),
                          const Divider(),
                          
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CommunityDetailPage(
                                        postId: postDoc.id,
                                        postData: post,
                                      ),
                                    ),
                                  );
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
          );
        },
      ),
    );
  }
}