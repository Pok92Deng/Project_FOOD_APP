import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditCommunityPostPage extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const EditCommunityPostPage({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<EditCommunityPostPage> createState() => _EditCommunityPostPageState();
}

class _EditCommunityPostPageState extends State<EditCommunityPostPage> {
  late TextEditingController captionController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    captionController = TextEditingController(
      text: (widget.postData['caption'] ?? '').toString(),
    );
  }

  Future<void> updatePost() async {
    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .update({
        'caption': captionController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แก้ไขโพสต์สำเร็จ')),
      );
      Navigator.pop(context);
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('แก้ไขโพสต์ชุมชน'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              TextField(
                controller: captionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'ข้อความประกอบโพสต์',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : updatePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('บันทึกการแก้ไข'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}