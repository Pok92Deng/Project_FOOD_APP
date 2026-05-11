import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_detail_page.dart';
import 'user_profile_page.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('ชุมชนสูตรอาหาร'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, postSnapshot) {
          if (!postSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('community_likes')
                .snapshots(),
            builder: (context, likeSnapshot) {
              if (!likeSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('community_comments')
                    .snapshots(),
                builder: (context, commentSnapshot) {
                  if (!commentSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final posts = postSnapshot.data!.docs;
                  final likes = likeSnapshot.data!.docs;
                  final comments = commentSnapshot.data!.docs;

                  if (posts.isEmpty) {
                    return const Center(
                      child: Text('ยังไม่มีโพสต์ในชุมชน'),
                    );
                  }

                  // ❤️ นับไลก์
                  final Map<String, int> likeCountMap = {};
                  for (final likeDoc in likes) {
                    final likeData = likeDoc.data() as Map<String, dynamic>;
                    final postId = (likeData['postId'] ?? '').toString();
                    if (postId.isNotEmpty) {
                      likeCountMap[postId] =
                          (likeCountMap[postId] ?? 0) + 1;
                    }
                  }

                  // 💬 นับคอมเมนต์
                  final Map<String, int> commentCountMap = {};
                  for (final commentDoc in comments) {
                    final commentData =
                        commentDoc.data() as Map<String, dynamic>;
                    final recipeId =
                        (commentData['recipeId'] ?? '').toString();
                    if (recipeId.isNotEmpty) {
                      commentCountMap[recipeId] =
                          (commentCountMap[recipeId] ?? 0) + 1;
                    }
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final postDoc = posts[index];
                      final postData =
                          postDoc.data() as Map<String, dynamic>;

                      final menuId =
                          (postData['menuId'] ?? '').toString();
                      final likeCount =
                          likeCountMap[postDoc.id] ?? 0;
                      final commentCount =
                          commentCountMap[postDoc.id] ?? 0;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('menus')
                            .doc(menuId)
                            .get(),
                        builder: (context, menuSnapshot) {
                          if (!menuSnapshot.hasData) {
                            return const SizedBox();
                          }

                          if (!menuSnapshot.data!.exists) {
                            return const SizedBox();
                          }

                          final menuData =
                              menuSnapshot.data!.data()
                                  as Map<String, dynamic>;

                          final imageUrl =
                              (menuData['imageUrl'] ?? '').toString();

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CommunityDetailPage(
                                    postId: postDoc.id,
                                    menuId: menuId,
                                    postData: postData,
                                    menuData: menuData,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin:
                                  const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 10,
                                    color: Colors.black.withOpacity(0.05),
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // 🖼 รูป
                                  if (imageUrl.isNotEmpty &&
                                      imageUrl.startsWith('http'))
                                    ClipRRect(
                                      borderRadius:
                                          const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: Image.network(
                                        imageUrl,
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error,
                                            stackTrace) {
                                          return Container(
                                            height: 180,
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: Icon(
                                                Icons.fastfood,
                                                size: 60,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  else
                                    Container(
                                      height: 180,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Icon(
                                          Icons.fastfood,
                                          size: 60,
                                        ),
                                      ),
                                    ),

                                  Padding(
                                    padding:
                                        const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (menuData['name'] ?? '')
                                              .toString(),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // 👤 กดชื่อไปโปรไฟล์
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    UserProfilePage(
                                                  userId: postData[
                                                      'userId'],
                                                  userEmail:
                                                      postData[
                                                          'userEmail'],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'แชร์โดย: ${(postData['userEmail'] ?? '').toString()}',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              decoration:
                                                  TextDecoration
                                                      .underline,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        Text(
                                          (postData['caption'] ?? '')
                                              .toString(),
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors
                                                .grey.shade700,
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        // ❤️ + 💬
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.favorite,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text('$likeCount'),
                                            const SizedBox(width: 16),
                                            const Icon(
                                              Icons.comment,
                                              color:
                                                  Colors.blueGrey,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text('$commentCount'),
                                          ],
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