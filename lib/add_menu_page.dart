import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // 🌟 ตัวแปรสำหรับระบบเลือกวัตถุดิบอัจฉริยะ
  List<Map<String, dynamic>> availableIngredients = []; 
  List<Map<String, dynamic>> selectedIngredients = []; 

  @override
  void initState() {
    super.initState();
    _loadIngredientsFromDB();
  }

  // 🌟 โหลดรายชื่อวัตถุดิบจากเว็บ Admin
  Future<void> _loadIngredientsFromDB() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('ingredients').get();
      if (mounted) {
        setState(() {
          availableIngredients = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading ingredients: $e");
    }
  }

  // 🌟 ฟังก์ชันคำนวณโภชนาการอัตโนมัติ (แก้ไขใหม่ให้ดึงข้อมูลแม่นยำขึ้น)
  void _calculateNutrition() {
    double totalCal = 0;
    double totalProtein = 0;

    for (var item in selectedIngredients) {
      final ing = item['ingredient'];
      final double grams = item['grams'];

      // ดึงค่าอย่างปลอดภัย (รองรับทั้งชื่อคีย์ cal และ calories)
      final double calPer100 = double.tryParse(ing['cal']?.toString() ?? ing['calories']?.toString() ?? '0') ?? 0.0;
      final double proteinPer100 = double.tryParse(ing['protein']?.toString() ?? '0') ?? 0.0;

      // สูตร: (ปริมาณที่ใช้ / 100) * ค่าโภชนาการต่อ 100 กรัม
      totalCal += (grams / 100) * calPer100;
      totalProtein += (grams / 100) * proteinPer100;
    }

    // อัปเดตตัวเลขลงในช่องให้ผู้ใช้เห็นทันที
    setState(() {
      caloriesController.text = totalCal.round().toString();
      proteinController.text = totalProtein.round().toString();
    });
  }

  // 🌟 ฟังก์ชันแสดงหน้าต่างเลือกวัตถุดิบ
  void _showAddIngredientDialog() {
    Map<String, dynamic>? currentSelectedIng;
    final TextEditingController gramsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.eco, color: Colors.green),
                  SizedBox(width: 8),
                  Text('เพิ่มวัตถุดิบ', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<Map<String, dynamic>>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('ค้นหา/เลือกวัตถุดิบ'),
                      value: currentSelectedIng,
                      items: availableIngredients.map((ing) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: ing,
                          child: Text(ing['name'] ?? 'ไม่มีชื่อ'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() => currentSelectedIng = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: gramsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ปริมาณที่ใช้ (กรัม)',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (currentSelectedIng != null && gramsController.text.isNotEmpty) {
                      setState(() {
                        selectedIngredients.add({
                          'ingredient': currentSelectedIng,
                          'grams': double.tryParse(gramsController.text.trim()) ?? 0,
                        });
                      });
                      _calculateNutrition(); // สั่งคำนวณทันทีหลังกดเพิ่ม
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('เพิ่มลงเมนู', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<String> uploadImage() async {
    if (selectedImage == null) return '';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref('menus/$fileName');
    final snapshot = await ref.putFile(selectedImage!);
    return await snapshot.ref.getDownloadURL();
  }

  List<String> textToList(String text) {
    if (text.isEmpty) return [];
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> addMenu() async {
    final name = nameController.text.trim();
    final category = categoryController.text.trim();
    final description = descriptionController.text.trim();
    
    if (name.isEmpty || category.isEmpty || description.isEmpty) {
      showMessage('กรุณากรอกชื่อเมนู ประเภท และรายละเอียดให้ครบ');
      return;
    }

    try {
      setState(() => isLoading = true);

      String imageUrl = '';
      if (selectedImage != null) {
        imageUrl = await uploadImage();
      }

      final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'ไม่ระบุตัวตน';

      // รวมวัตถุดิบจากระบบคำนวณและที่พิมพ์เองเข้าด้วยกัน
      List<String> finalIngredientsList = selectedIngredients.map((item) {
        return "${item['ingredient']['name']} ${item['grams']} กรัม";
      }).toList();
      finalIngredientsList.addAll(textToList(ingredientsController.text));

      // บันทึกลง Firestore
      await FirebaseFirestore.instance.collection('menus').add({
        'name': name,
        'category': category,
        'description': description,
        'ingredients': finalIngredientsList,
        'steps': textToList(stepsController.text),
        'calories': int.tryParse(caloriesController.text.trim()) ?? 0,
        'protein': int.tryParse(proteinController.text.trim()) ?? 0,
        'suitableForDisease': textToList(suitableForDiseaseController.text),
        'suitableForGoal': textToList(suitableForGoalController.text),
        'imageUrl': imageUrl,
        'authorEmail': userEmail,
        'status': 'pending', 
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      showMessage('เพิ่มเมนูสำเร็จ (รอตรวจสอบ)');
      Navigator.pop(context);
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
        title: const Text('สร้างเมนูสุขภาพ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                child: selectedImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(selectedImage!, fit: BoxFit.cover))
                    : const Center(child: Text('กดเพื่อเลือกรูปหน้าปกเมนู')),
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ข้อมูลทั่วไป', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: nameController, decoration: inputStyle('ชื่อเมนู', Icons.restaurant)),
                  const SizedBox(height: 16),
                  TextField(controller: categoryController, decoration: inputStyle('ประเภทอาหาร', Icons.category)),
                  const SizedBox(height: 16),
                  TextField(controller: descriptionController, maxLines: 3, decoration: inputStyle('รายละเอียดเมนู', Icons.description)),
                  
                  const Divider(height: 40, thickness: 1),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('วัตถุดิบหลัก (คำนวณโภชนาการ)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                      TextButton.icon(
                        onPressed: availableIngredients.isEmpty ? null : _showAddIngredientDialog,
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        label: Text(availableIngredients.isEmpty ? 'กำลังโหลด...' : 'เพิ่ม', style: const TextStyle(color: Colors.green)),
                      )
                    ],
                  ),
                  
                  if (selectedIngredients.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: selectedIngredients.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final data = entry.value;
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            title: Text(data['ingredient']['name']),
                            subtitle: Text('${data['grams']} กรัม'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  selectedIngredients.removeAt(idx);
                                });
                                _calculateNutrition(); // ลบแล้วให้คำนวณใหม่
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  TextField(
                    controller: ingredientsController,
                    maxLines: 2,
                    decoration: inputStyle('วัตถุดิบอื่นๆ (พิมพ์เอง, คั่นด้วยลูกน้ำ ,)', Icons.shopping_basket),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: stepsController,
                    maxLines: 4,
                    decoration: inputStyle('วิธีทำ (คั่นแต่ละขั้นตอนด้วยลูกน้ำ ,)', Icons.menu_book),
                  ),

                  const Divider(height: 40, thickness: 1),

                  const Text('ข้อมูลโภชนาการ (อัตโนมัติ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('*ตัวเลขนี้ถูกคำนวณจากวัตถุดิบหลักที่คุณเลือก (สามารถแก้ไขเองได้)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: caloriesController,
                          keyboardType: TextInputType.number,
                          decoration: inputStyle('แคลอรี่ (kcal)', Icons.local_fire_department),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: proteinController,
                          keyboardType: TextInputType.number,
                          decoration: inputStyle('โปรตีน (g)', Icons.fitness_center),
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 40, thickness: 1),

                  const Text('แนะนำสำหรับ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: suitableForDiseaseController, decoration: inputStyle('โรคประจำตัวที่ทานได้ (คั่นด้วย ,)', Icons.health_and_safety)),
                  const SizedBox(height: 16),
                  TextField(controller: suitableForGoalController, decoration: inputStyle('เป้าหมาย (คั่นด้วย ,)', Icons.flag)),
                  
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : addMenu,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('บันทึกเมนูสุขภาพ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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