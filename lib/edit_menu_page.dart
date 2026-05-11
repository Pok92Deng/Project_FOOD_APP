import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.menu.name);
    categoryController = TextEditingController(text: widget.menu.category);
    descriptionController = TextEditingController(text: widget.menu.description);
    ingredientsController = TextEditingController(text: widget.menu.ingredients);
    stepsController = TextEditingController(text: widget.menu.steps);
    caloriesController = TextEditingController(text: widget.menu.calories);
    proteinController = TextEditingController(text: widget.menu.protein);
    suitableForDiseaseController =
        TextEditingController(text: widget.menu.suitableForDisease);
    suitableForGoalController =
        TextEditingController(text: widget.menu.suitableForGoal);
  }

  Future<void> updateMenu() async {
    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance
          .collection('menus')
          .doc(widget.menu.id)
          .update({
        'name': nameController.text.trim(),
        'category': categoryController.text.trim(),
        'description': descriptionController.text.trim(),
        'ingredients': ingredientsController.text.trim(),
        'steps': stepsController.text.trim(),
        'calories': caloriesController.text.trim(),
        'protein': proteinController.text.trim(),
        'suitableForDisease': suitableForDiseaseController.text.trim(),
        'suitableForGoal': suitableForGoalController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกการแก้ไขสำเร็จ')),
      );
      Navigator.pop(context);
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> deleteMenu() async {
    try {
      await FirebaseFirestore.instance
          .collection('menus')
          .doc(widget.menu.id)
          .delete();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      showMessage('Error: $e');
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
        title: const Text('แก้ไขเมนู'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: deleteMenu,
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                decoration: inputStyle('พลังงาน', Icons.local_fire_department),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: proteinController,
                decoration: inputStyle('โปรตีน', Icons.fitness_center),
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
                  onPressed: isLoading ? null : updateMenu,
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