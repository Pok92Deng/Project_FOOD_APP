import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // เพิ่ม import นี้สำหรับดึงอีเมล

class AddMenuPage extends StatefulWidget {
  const AddMenuPage({super.key});

  @override
  State<AddMenuPage> createState() => _AddMenuPageState();
}

class _AddMenuPageState extends State<AddMenuPage> {
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  final descriptionController = TextEditingController();
  final ingredientsController = TextEditingController();
  final stepsController = TextEditingController();
  final caloriesController = TextEditingController();
  final proteinController = TextEditingController();
  final suitableForDiseaseController = TextEditingController();
  final suitableForGoalController = TextEditingController();

  File? selectedImage;
  bool isLoading = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<String> uploadImage() async {
    if (selectedImage == null) return '';

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref('menus/$fileName');
    final snapshot = await ref.putFile(selectedImage!);
    return await snapshot.ref.getDownloadURL();
  }

  // ฟังก์ชันตัวช่วยสำหรับแยกข้อความ (String) ให้กลายเป็นรายการ (List) โดยใช้ลูกน้ำ (,)
  List<String> textToList(String text) {
    if (text.isEmpty) return [];
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> addMenu() async {
    final name = nameController.text.trim();
    final category = categoryController.text.trim();
    final description = descriptionController.text.trim();
    
    if (name.isEmpty || category.isEmpty || description.isEmpty) {
      showMessage('กรุณากรอกชื่อเมนู ประเภท และรายละเอียด');
      return;
    }

    try {
      setState(() => isLoading = true);

      String imageUrl = '';
      if (selectedImage != null) {
        imageUrl = await uploadImage();
      }

      // ดึงอีเมลของผู้ที่กำลังล็อกอินอยู่
      final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'ไม่ระบุตัวตน';

      // บันทึกข้อมูลลง Firestore ด้วยรูปแบบใหม่ (แปลง String เป็น List และ int)
      await FirebaseFirestore.instance.collection('menus').add({
        'name': name,
        'category': category,
        'description': description,
        'ingredients': textToList(ingredientsController.text),
        'steps': textToList(stepsController.text),
        'calories': int.tryParse(caloriesController.text.trim()) ?? 0,
        'protein': int.tryParse(proteinController.text.trim()) ?? 0,
        'suitableForDisease': textToList(suitableForDiseaseController.text),
        'suitableForGoal': textToList(suitableForGoalController.text),
        'imageUrl': imageUrl,
        'authorEmail': userEmail, // เพิ่มผู้สร้างเมนู
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      showMessage('เพิ่มเมนูสำเร็จ');
      Navigator.pop(context);
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    ingredientsController.dispose();
    stepsController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    suitableForDiseaseController.dispose();
    suitableForGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('เพิ่มเมนูสุขภาพ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(selectedImage!, fit: BoxFit.cover),
                      )
                    : const Center(
                        child: Text('กดเพื่อเลือกรูป'),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: inputStyle('ชื่อเมนู', Icons.restaurant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: categoryController,
                    decoration: inputStyle('ประเภทอาหาร', Icons.category),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: inputStyle('รายละเอียดเมนู', Icons.description),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ingredientsController,
                    maxLines: 3,
                    decoration: inputStyle('วัตถุดิบ (คั่นแต่ละอย่างด้วยลูกน้ำ ,)', Icons.shopping_basket),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: stepsController,
                    maxLines: 4,
                    decoration: inputStyle('วิธีทำ (คั่นแต่ละขั้นตอนด้วยลูกน้ำ ,)', Icons.menu_book),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: inputStyle('พลังงาน (ใส่ตัวเลข เช่น 250)', Icons.local_fire_department),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: proteinController,
                    keyboardType: TextInputType.number,
                    decoration: inputStyle('โปรตีน (ใส่ตัวเลข เช่น 30)', Icons.fitness_center),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: suitableForDiseaseController,
                    decoration: inputStyle('เหมาะกับโรค (คั่นด้วยลูกน้ำ ,)', Icons.health_and_safety),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: suitableForGoalController,
                    decoration: inputStyle('เหมาะกับเป้าหมาย (คั่นด้วยลูกน้ำ ,)', Icons.flag),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : addMenu,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // เปลี่ยนเป็นสีเขียวให้เข้ากับแอปสุขภาพ
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('บันทึกเมนู', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}