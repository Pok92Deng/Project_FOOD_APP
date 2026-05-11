import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_comment_section.dart';
import 'edit_community_post_page.dart';
import 'user_profile_page.dart';

class CommunityDetailPage extends StatefulWidget {
  final String postId;
  final String menuId;
  final Map<String, dynamic> postData;
  final Map<String, dynamic> menuData;

  const CommunityDetailPage({
    super.key,
    required this.postId,
    required this.menuId,
    required this.postData,
    required this.menuData,
  });

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  bool isLiked = false;
  String? likeDocId;

  @override
  void initState() {
    super.initState();
    checkLikeStatus();
  }

  Future<void> checkLikeStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('community_likes')
        .where('postId', isEqualTo: widget.postId)
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        isLiked = true;
        likeDocId = snapshot.docs.first.id;
      });
    }
  }

  Future<void> toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (isLiked && likeDocId != null) {
      await FirebaseFirestore.instance
          .collection('community_likes')
          .doc(likeDocId)
          .delete();

      setState(() {
        isLiked = false;
        likeDocId = null;
      });
    } else {
      final doc =
          await FirebaseFirestore.instance.collection('community_likes').add({
        'postId': widget.postId,
        'userId': currentUser.uid,
        'createdAt': Timestamp.now(),
      });

      setState(() {
        isLiked = true;
        likeDocId = doc.id;
      });
    }
  }

  Future<void> deletePost(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบโพสต์สำเร็จ')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final postOwnerId = (widget.postData['userId'] ?? '').toString();
    final isOwner = currentUser != null && currentUser.uid == postOwnerId;

    final imageUrl = (widget.menuData['imageUrl'] ?? '').toString();
    final name = (widget.menuData['name'] ?? '').toString();
    final category = (widget.menuData['category'] ?? '').toString();
    final description = (widget.menuData['description'] ?? '').toString();
    final ingredients = (widget.menuData['ingredients'] ?? '').toString();
    final steps = (widget.menuData['steps'] ?? '').toString();

    final caption = (widget.postData['caption'] ?? '').toString();
    final userEmail = (widget.postData['userEmail'] ?? '').toString();
    final userId = (widget.postData['userId'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('โพสต์จากชุมชน'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: toggleLike,
          ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditCommunityPostPage(
                      postId: widget.postId,
                      postData: widget.postData,
                    ),
                  ),
                );
              },
            ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('ยืนยันการลบ'),
                    content: const Text('ต้องการลบโพสต์นี้ใช่หรือไม่?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('ยกเลิก'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('ลบ'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await deletePost(context);
                }
              },
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
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(
                          userId: userId,
                          userEmail: userEmail,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'แชร์โดย $userEmail',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('community_likes')
                      .where('postId', isEqualTo: widget.postId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final likeCount = snapshot.data?.docs.length ?? 0;

                    return Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text('$likeCount คนถูกใจโพสต์นี้'),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                buildInfoCard(
                  title: 'ข้อความจากผู้แชร์',
                  value: caption,
                  icon: Icons.campaign,
                  color: Colors.orange,
                ),
                buildInfoCard(
                  title: 'ประเภทอาหาร',
                  value: category,
                  icon: Icons.category,
                  color: Colors.blue,
                ),
                buildInfoCard(
                  title: 'รายละเอียด',
                  value: description,
                  icon: Icons.description,
                  color: Colors.teal,
                ),
                buildInfoCard(
                  title: 'วัตถุดิบ',
                  value: ingredients,
                  icon: Icons.shopping_basket,
                  color: Colors.green,
                ),
                buildInfoCard(
                  title: 'วิธีทำ',
                  value: steps,
                  icon: Icons.menu_book,
                  color: Colors.purple,
                ),

                const SizedBox(height: 24),

                CommunityCommentSection(recipeId: widget.postId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}