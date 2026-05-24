import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityDetailPage extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const CommunityDetailPage({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อคอมเมนต์')));
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('community_comments').add({
        'postId': widget.postId,
        'userId': user.uid,
        'userEmail': user.email ?? 'ไม่ระบุตัวตน',
        'comment': comment,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      _commentController.clear();
      FocusScope.of(context).unfocus(); // ปิดคีย์บอร์ดหลังจากส่งข้อความ
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
    final String userEmail = widget.postData['userEmail']?.toString() ?? 'ไม่ระบุตัวตน';
    final String username = userEmail.isNotEmpty && userEmail != 'ไม่ระบุตัวตน' ? userEmail.split('@')[0] : 'U';
    final String caption = widget.postData['caption']?.toString() ?? '';
    final List<dynamic> likes = widget.postData['likes'] is List ? List.from(widget.postData['likes']) : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('โพสต์ของชุมชน', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // 1. ส่วนแสดงเนื้อหาโพสต์ต้นฉบับ
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : 'U', 
                        style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                if (caption.isNotEmpty) Text(caption, style: const TextStyle(fontSize: 16, height: 1.4)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 6),
                    Text('${likes.length} คนถูกใจสิ่งนี้', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1),

          // 2. ส่วนแสดงรายการความคิดเห็น (แก้ไขถอน orderBy เพื่อป้องกันปัญหา Index ของ Firebase)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_comments')
                  .where('postId', isEqualTo: widget.postId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final rawComments = snapshot.data?.docs ?? [];

                if (rawComments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('ยังไม่มีความคิดเห็น\nเป็นคนแรกที่คอมเมนต์สิ!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                // นำคอมเมนต์มาจัดเรียงเวลาในเครื่องมือถือแทน (เก่าไปใหม่ ใครพิมพ์ก่อนอยู่บน)
                var comments = rawComments.toList();
                comments.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return aTime.compareTo(bTime);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;
                    final commenterName = (data['userEmail']?.toString() ?? 'User').split('@')[0];
                    final commentText = data['comment']?.toString() ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(commenterName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                          const SizedBox(height: 4),
                          Text(commentText, style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 3. ส่วนพิมพ์คอมเมนต์ด้านล่างสุด
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'แสดงความคิดเห็น...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.green),
                  onPressed: _isSubmitting ? null : _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}