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
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อแสดงความคิดเห็น')));
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'menuId': widget.menuId,
        'userId': user.uid,
        'userEmail': user.email ?? 'ไม่ระบุชื่อ',
        'rating': _selectedRating,
        'comment': comment,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      _commentController.clear();
      setState(() => _selectedRating = 5);
      FocusScope.of(context).unfocus(); // ปิดคีย์บอร์ด
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ขอบคุณสำหรับรีวิวของคุณ!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40, thickness: 1),
        const Text('รีวิวและความคิดเห็น', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        // ฟอร์มสำหรับกรอกรีวิว
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ให้คะแนนเมนูนี้', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(index < _selectedRating ? Icons.star : Icons.star_border, color: Colors.orange, size: 30),
                    onPressed: () => setState(() => _selectedRating = index + 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'เขียนความคิดเห็นของคุณที่นี่...',
                  filled: true, fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: _isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('ส่งรีวิว', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // แสดงรายการรีวิวทั้งหมด
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('reviews').where('menuId', isEqualTo: widget.menuId).orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return const Text('ไม่สามารถโหลดรีวิวได้');
            
            final reviews = snapshot.data?.docs ?? [];
            if (reviews.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('ยังไม่มีรีวิวสำหรับเมนูนี้ เป็นคนแรกที่รีวิวสิ!', style: TextStyle(color: Colors.grey.shade600))));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // ปิดการเลื่อนซ้อนกัน
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index].data() as Map<String, dynamic>;
                final rating = review['rating'] ?? 5;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(review['userEmail'].toString().split('@')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Row(
                            children: List.generate(5, (starIndex) => Icon(starIndex < rating ? Icons.star : Icons.star_border, color: Colors.orange, size: 16)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(review['comment'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}