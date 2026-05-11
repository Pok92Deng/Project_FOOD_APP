import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  Future<void> addMenu() async {
    final name = nameController.text.trim();
    final category = categoryController.text.trim();
    final description = descriptionController.text.trim();
    final ingredients = ingredientsController.text.trim();
    final steps = stepsController.text.trim();
    final calories = caloriesController.text.trim();
    final protein = proteinController.text.trim();
    final suitableForDisease = suitableForDiseaseController.text.trim();
    final suitableForGoal = suitableForGoalController.text.trim();

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

      await FirebaseFirestore.instance.collection('menus').add({
        'name': name,
        'category': category,
        'description': description,
        'ingredients': ingredients,
        'steps': steps,
        'calories': calories,
        'protein': protein,
        'suitableForDisease': suitableForDisease,
        'suitableForGoal': suitableForGoal,
        'imageUrl': imageUrl,
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
                    decoration: inputStyle('วัตถุดิบ', Icons.shopping_basket),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: stepsController,
                    maxLines: 4,
                    decoration: inputStyle('วิธีทำ', Icons.menu_book),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: caloriesController,
                    decoration: inputStyle('พลังงาน เช่น 250 kcal', Icons.local_fire_department),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: proteinController,
                    decoration: inputStyle('โปรตีน เช่น 30 g', Icons.fitness_center),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: suitableForDiseaseController,
                    decoration: inputStyle('เหมาะกับโรค', Icons.health_and_safety),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: suitableForGoalController,
                    decoration: inputStyle('เหมาะกับเป้าหมายสุขภาพ', Icons.flag),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : addMenu,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('บันทึกเมนู'),
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