import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewSection extends StatefulWidget {
  final String menuId;

  const ReviewSection({super.key, required this.menuId});

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final commentController = TextEditingController();
  double rating = 3;
  bool isLoading = false;

  Future<void> submitReview() async {
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

      await FirebaseFirestore.instance.collection('reviews').add({
        'menuId': widget.menuId,
        'userEmail': user.email ?? 'ไม่ทราบผู้ใช้',
        'comment': comment,
        'rating': rating,
        'createdAt': Timestamp.now(),
      });

      commentController.clear();
      setState(() {
        rating = 3;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกรีวิวสำเร็จ')),
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

  Widget buildStars() {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return IconButton(
          onPressed: () {
            setState(() {
              rating = starValue.toDouble();
            });
          },
          icon: Icon(
            starValue <= rating ? Icons.star : Icons.star_border,
            color: Colors.orange,
          ),
        );
      }),
    );
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
          'รีวิวและความคิดเห็น',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        buildStars(),
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
            onPressed: isLoading ? null : submitReview,
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('ส่งรีวิว'),
          ),
        ),
        const SizedBox(height: 20),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('menuId', isEqualTo: widget.menuId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final reviews = snapshot.data!.docs;

            if (reviews.isEmpty) {
              return const Text('ยังไม่มีรีวิว');
            }

            return Column(
              children: reviews.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final reviewRating = (data['rating'] ?? 0).toDouble();

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
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < reviewRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.orange,
                            size: 18,
                          );
                        }),
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