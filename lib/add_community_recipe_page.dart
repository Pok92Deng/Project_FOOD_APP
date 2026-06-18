import 'dart:io'; // 🌟 เพิ่ม import สำหรับจัดการไฟล์
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 🌟 สำหรับอัปโหลดรูป
import 'package:image_picker/image_picker.dart'; // 🌟 สำหรับเลือกรูปจากเครื่อง

class AddCommunityRecipePage extends StatefulWidget {
  const AddCommunityRecipePage({super.key});

  @override
  State<AddCommunityRecipePage> createState() => _AddCommunityRecipePageState();
}

class _AddCommunityRecipePageState extends State<AddCommunityRecipePage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final ingredientsController = TextEditingController();
  final stepsController = TextEditingController();

  bool isLoading = false;
  
  // 🌟 ตัวแปรสำหรับเก็บไฟล์รูปที่เลือก
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // 🌟 ฟังก์ชันเลือกรูปจากแกลลอรี
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70); // บีบอัดรูปนิดนึงไม่ให้หนักเกินไป
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> addPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อสูตรอาหาร')));
      return;
    }

    try {
      setState(() => isLoading = true);

      String imageUrl = '';

      // 🌟 1. ถ้ามีการเลือกรูปภาพ ให้ทำการอัปโหลดขึ้น Firebase Storage ก่อน
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('community_images')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL(); // ได้ลิงก์รูปภาพมาแล้ว!
      }

      // 🌟 2. นำข้อมูลทั้งหมดรวมถึงลิงก์รูปภาพไปบันทึกลง Firestore
      await FirebaseFirestore.instance.collection('community_posts').add({ // 🚨 สำคัญ: แอดมินดึงข้อมูลจาก community_posts (ถ้าตารางหลักคุณชื่อ community_recipes ให้เปลี่ยนให้ตรงกันนะครับ)
        'userId': user.uid,
        'userEmail': user.email,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'ingredients': ingredientsController.text.trim(),
        'steps': stepsController.text.trim(),
        'imageUrl': imageUrl, // 🌟 ฟิลด์ใหม่ที่เราเพิ่มเข้ามา!
        'createdAt': Timestamp.now(),
        'likes': [], // เพิ่มฟิลด์เผื่อระบบไลก์
        'reportCount': 0, // ค่าเริ่มต้นสำหรับระบบแอดมิน
        'status': 'published'
      });

      if (!mounted) return;
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    ingredientsController.dispose();
    stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('โพสต์สูตรใหม่')),
      body: SingleChildScrollView( // 🌟 ใส่ ScrollView ป้องกันคีย์บอร์ดบังหน้าจอเวลาพิมพ์
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🌟 กล่องสำหรับกดเลือกรูปภาพ
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_imageFile!, fit: BoxFit.cover), // โชว์รูปที่เลือก
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.blue.shade300),
                          const SizedBox(height: 10),
                          Text('เพิ่มรูปภาพประกอบ (ถ้ามี)', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'ชื่อสูตรอาหาร*', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: descriptionController, maxLines: 2, decoration: const InputDecoration(labelText: 'รายละเอียด', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: ingredientsController, maxLines: 3, decoration: const InputDecoration(labelText: 'วัตถุดิบ (เช่น หมู 100g, ไข่ 1 ฟอง)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: stepsController, maxLines: 4, decoration: const InputDecoration(labelText: 'วิธีทำ', border: OutlineInputBorder())),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: isLoading ? null : addPost,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('โพสต์ลงชุมชน', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}