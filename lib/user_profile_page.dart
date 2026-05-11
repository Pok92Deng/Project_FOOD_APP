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
          stream: FirebaseFirestore.instance
              .collection('community_posts')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, postSnapshot) {
            if (!postSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final posts = postSnapshot.data!.docs;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_likes')
                  .snapshots(),
              builder: (context, likeSnapshot) {
                if (!likeSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final likes = likeSnapshot.data!.docs;

                int totalLikes = 0;

                for (final likeDoc in likes) {
                  final likeData =
                      likeDoc.data() as Map<String, dynamic>;

                  final postId =
                      (likeData['postId'] ?? '').toString();

                  final hasPost = posts.any(
                    (post) => post.id == postId,
                  );

                  if (hasPost) {
                    totalLikes++;
                  }
                }

                return Column(
                  children: [
                    // 🔥 Header Profile
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFF9F43),
                            Color(0xFFFF6B6B),
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 👤 Avatar
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white,
                            child: Text(
                              userEmail.isNotEmpty
                                  ? userEmail[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            userEmail,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 📊 Stats
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
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
                          ? const Center(
                              child: Text('ยังไม่มีโพสต์'),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                final postDoc = posts[index];

                                final postData =
                                    postDoc.data()
                                        as Map<String, dynamic>;

                                final menuId =
                                    (postData['menuId'] ?? '')
                                        .toString();

                                return FutureBuilder<
                                    DocumentSnapshot>(
                                  future: FirebaseFirestore
                                      .instance
                                      .collection('menus')
                                      .doc(menuId)
                                      .get(),
                                  builder:
                                      (context, menuSnapshot) {
                                    if (!menuSnapshot.hasData ||
                                        !menuSnapshot
                                            .data!.exists) {
                                      return const SizedBox();
                                    }

                                    final menuData =
                                        menuSnapshot.data!
                                                .data()
                                            as Map<String,
                                                dynamic>;

                                    final imageUrl =
                                        (menuData[
                                                    'imageUrl'] ??
                                                '')
                                            .toString();

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CommunityDetailPage(
                                              postId:
                                                  postDoc.id,
                                              menuId:
                                                  menuId,
                                              postData:
                                                  postData,
                                              menuData:
                                                  menuData,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              blurRadius: 10,
                                              color: Colors
                                                  .black
                                                  .withOpacity(
                                                      0.05),
                                              offset:
                                                  const Offset(
                                                0,
                                                4,
                                              ),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            // 🖼 รูป
                                            if (imageUrl
                                                    .isNotEmpty &&
                                                imageUrl.startsWith(
                                                    'http'))
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius
                                                        .vertical(
                                                  top: Radius
                                                      .circular(
                                                          20),
                                                ),
                                                child:
                                                    Image.network(
                                                  imageUrl,
                                                  height: 180,
                                                  width: double
                                                      .infinity,
                                                  fit: BoxFit
                                                      .cover,
                                                  errorBuilder:
                                                      (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Container(
                                                      height:
                                                          180,
                                                      color: Colors
                                                          .grey
                                                          .shade200,
                                                      child:
                                                          const Center(
                                                        child:
                                                            Icon(
                                                          Icons
                                                              .fastfood,
                                                          size:
                                                              60,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            else
                                              Container(
                                                height: 180,
                                                color: Colors
                                                    .grey
                                                    .shade200,
                                                child:
                                                    const Center(
                                                  child: Icon(
                                                    Icons
                                                        .fastfood,
                                                    size: 60,
                                                  ),
                                                ),
                                              ),

                                            Padding(
                                              padding:
                                                  const EdgeInsets
                                                      .all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    (menuData[
                                                                'name'] ??
                                                            '')
                                                        .toString(),
                                                    style:
                                                        const TextStyle(
                                                      fontSize:
                                                          20,
                                                      fontWeight:
                                                          FontWeight
                                                              .bold,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      height:
                                                          8),
                                                  Text(
                                                    (postData[
                                                                'caption'] ??
                                                            '')
                                                        .toString(),
                                                    maxLines:
                                                        2,
                                                    overflow:
                                                        TextOverflow
                                                            .ellipsis,
                                                    style:
                                                        TextStyle(
                                                      color: Colors
                                                          .grey
                                                          .shade700,
                                                    ),
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
            );
          },
        ),
      ),
    );
  }

  Widget buildStatItem({
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}