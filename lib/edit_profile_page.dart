import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final diseaseController = TextEditingController();
  final bioController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  // 🌟 ดึงข้อมูลเดิมมาแสดงในช่องกรอก
  Future<void> _loadCurrentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['displayName'] ?? '';
          weightController.text = (data['weight'] ?? 0).toString();
          heightController.text = (data['height'] ?? 0).toString();
          diseaseController.text = data['disease'] ?? 'ไม่มี';
          bioController.text = data['bio'] ?? '';
          isLoading = false;
        });
      }
    }
  }

  // 🌟 บันทึกข้อมูลกลับเข้า Firestore
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'displayName': nameController.text.trim(),
          'weight': double.tryParse(weightController.text.trim()) ?? 0,
          'height': double.tryParse(heightController.text.trim()) ?? 0,
          'disease': diseaseController.text.trim().isEmpty ? 'ไม่มี' : diseaseController.text.trim(),
          'bio': bioController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปเดตข้อมูลโปรไฟล์เรียบร้อย!')),
          );
          Navigator.pop(context); // บันทึกเสร็จให้เด้งกลับหน้าเดิม
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    weightController.dispose();
    heightController.dispose();
    diseaseController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลส่วนตัว', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ฟอร์มกรอกชื่อ
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อแสดงผล',
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // ฟอร์มกรอกน้ำหนักและส่วนสูง (แสดงแนวนอน)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: weightController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'น้ำหนัก (กก.)',
                              prefixIcon: const Icon(Icons.monitor_weight),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: heightController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'ส่วนสูง (ซม.)',
                              prefixIcon: const Icon(Icons.height),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ฟอร์มกรอกโรคประจำตัว
                    TextFormField(
                      controller: diseaseController,
                      decoration: InputDecoration(
                        labelText: 'โรคประจำตัว (ถ้าไม่มีให้ใส่คำว่า "ไม่มี")',
                        prefixIcon: const Icon(Icons.medical_services),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ฟอร์มกรอกประวัติย่อ
                    TextFormField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'คำแนะนำตัว (Bio)',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 30),
                          child: Icon(Icons.description),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ปุ่มบันทึก
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}