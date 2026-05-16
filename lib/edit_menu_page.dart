import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'menu_model.dart';

class EditMenuPage extends StatefulWidget {
  final MenuModel menu;

  const EditMenuPage({super.key, required this.menu});

  @override
  State<EditMenuPage> createState() => _EditMenuPageState();
}

class _EditMenuPageState extends State<EditMenuPage> {
  late TextEditingController nameController;
  late TextEditingController categoryController;
  late TextEditingController descriptionController;
  late TextEditingController ingredientsController;
  late TextEditingController stepsController;
  late TextEditingController caloriesController;
  late TextEditingController proteinController;
  late TextEditingController suitableForDiseaseController;
  late TextEditingController suitableForGoalController;

  File? selectedImage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // แปลงข้อมูลจาก Model มาใส่ใน Controller (ถ้าเป็น List ให้รวมเป็น String ด้วยลูกน้ำ)
    nameController = TextEditingController(text: widget.menu.name);
    categoryController = TextEditingController(text: widget.menu.category);
    descriptionController = TextEditingController(text: widget.menu.description);
    ingredientsController = TextEditingController(text: widget.menu.ingredients.join(', '));
    stepsController = TextEditingController(text: widget.menu.steps.join(', '));
    caloriesController = TextEditingController(text: widget.menu.calories.toString());
    proteinController = TextEditingController(text: widget.menu.protein.toString());
    suitableForDiseaseController = TextEditingController(text: widget.menu.suitableForDisease.join(', '));
    suitableForGoalController = TextEditingController(text: widget.menu.suitableForGoal.join(', '));
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

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  List<String> textToList(String text) {
    if (text.isEmpty) return [];
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> updateMenu() async {
    try {
      setState(() => isLoading = true);
      String imageUrl = widget.menu.imageUrl;

      if (selectedImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref('menus/$fileName');
        final snapshot = await ref.putFile(selectedImage!);
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('menus').doc(widget.menu.id).update({
        'name': nameController.text.trim(),
        'category': categoryController.text.trim(),
        'description': descriptionController.text.trim(),
        'ingredients': textToList(ingredientsController.text),
        'steps': textToList(stepsController.text),
        'calories': int.tryParse(caloriesController.text) ?? 0,
        'protein': int.tryParse(proteinController.text) ?? 0,
        'suitableForDisease': textToList(suitableForDiseaseController.text),
        'suitableForGoal': textToList(suitableForGoalController.text),
        'imageUrl': imageUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แก้ไขข้อมูลเมนูสำเร็จ')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('แก้ไขเมนูอาหาร'),
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
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(selectedImage!, fit: BoxFit.cover),
                      )
                    : (widget.menu.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(widget.menu.imageUrl, fit: BoxFit.cover),
                          )
                        : const Center(child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey))),
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
                  TextField(controller: nameController, decoration: inputStyle('ชื่อเมนู', Icons.restaurant)),
                  const SizedBox(height: 16),
                  TextField(controller: categoryController, decoration: inputStyle('ประเภทอาหาร', Icons.category)),
                  const SizedBox(height: 16),
                  TextField(controller: descriptionController, maxLines: 2, decoration: inputStyle('รายละเอียด', Icons.description)),
                  const SizedBox(height: 16),
                  TextField(controller: ingredientsController, maxLines: 2, decoration: inputStyle('วัตถุดิบ (คั่นด้วยลูกน้ำ)', Icons.shopping_basket)),
                  const SizedBox(height: 16),
                  TextField(controller: stepsController, maxLines: 3, decoration: inputStyle('วิธีทำ (คั่นด้วยลูกน้ำ)', Icons.menu_book)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: caloriesController, keyboardType: TextInputType.number, decoration: inputStyle('แคลอรี่', Icons.local_fire_department))),
                      const SizedBox(width: 16),
                      Expanded(child: TextField(controller: proteinController, keyboardType: TextInputType.number, decoration: inputStyle('โปรตีน (g)', Icons.fitness_center))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: suitableForDiseaseController, decoration: inputStyle('เหมาะกับโรค', Icons.health_and_safety)),
                  const SizedBox(height: 16),
                  TextField(controller: suitableForGoalController, decoration: inputStyle('เหมาะกับเป้าหมายสุขภาพ', Icons.flag)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : updateMenu,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('บันทึกการเปลี่ยนแปลง', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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