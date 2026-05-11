import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityCommentSection extends StatefulWidget {
  final String recipeId;

  const CommunityCommentSection({super.key, required this.recipeId});

  @override
  State<CommunityCommentSection> createState() =>
      _CommunityCommentSectionState();
}

class _CommunityCommentSectionState extends State<CommunityCommentSection> {
  final commentController = TextEditingController();
  bool isLoading = false;

  Future<void> submitComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final comment = commentController.text.trim();

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกความคิดเห็น')),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseFirestore.instance.collection('community_comments').add({
        'recipeId': widget.recipeId,
        'userId': user.uid,
        'userEmail': user.email ?? 'ไม่ทราบผู้ใช้',
        'comment': comment,
        'createdAt': Timestamp.now(),
      });

      commentController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งความคิดเห็นสำเร็จ')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ความคิดเห็นจากชุมชน',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'เขียนความคิดเห็น...',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : submitComment,
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('ส่งความคิดเห็น'),
          ),
        ),
        const SizedBox(height: 20),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('community_comments')
              .where('recipeId', isEqualTo: widget.recipeId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final comments = snapshot.data!.docs;

            if (comments.isEmpty) {
              return const Text('ยังไม่มีความคิดเห็น');
            }

            return Column(
              children: comments.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userEmail'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(data['comment'] ?? ''),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}