import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  final _displayNameController = TextEditingController();
  final _ageController = TextEditingController(); 
  final _weightController = TextEditingController(); 
  final _heightController = TextEditingController(); // 🌟 เพิ่มตัวรับค่าส่วนสูง
  final _diseaseController = TextEditingController(); 
  
  // 🌟 เพิ่มตัวเลือกเป้าหมายสุขภาพ
  final List<String> _goalOptions = ['ไม่ระบุ', 'ลดน้ำหนัก', 'เพิ่มกล้ามเนื้อ', 'รักษาสุขภาพ', 'อาหารคลีน', 'คีโต', 'มังสวิรัติ'];
  String _selectedGoal = 'ไม่ระบุ';
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _displayNameController.text = data['displayName'] ?? '';
          _ageController.text = data['age']?.toString() ?? ''; 
          _weightController.text = data['weight']?.toString() ?? ''; 
          _heightController.text = data['height']?.toString() ?? ''; 
          _diseaseController.text = data['disease'] ?? ''; 
          
          // เช็คว่าเป้าหมายที่มีอยู่ในฐานข้อมูล ตรงกับตัวเลือกในลิสต์หรือไม่
          if (data['goal'] != null && _goalOptions.contains(data['goal'])) {
            _selectedGoal = data['goal'];
          }
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _displayNameController.text.trim(),
          'age': _ageController.text.trim(), 
          'weight': _weightController.text.trim(),
          'height': _heightController.text.trim(), // 🌟 บันทึกส่วนสูง
          'disease': _diseaseController.text.trim(),
          'goal': _selectedGoal, // 🌟 บันทึกเป้าหมาย
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลโปรไฟล์สำเร็จ! ✅'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _diseaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('จัดการข้อมูลส่วนตัว', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ข้อมูลบัญชีผู้ใช้', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อผู้ใช้ (Display Name)',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อ' : null,
              ),
              
              const SizedBox(height: 32),
              const Text('ข้อมูลสำหรับประเมินสุขภาพ 🩺', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // 🌟 อายุ
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'อายุ (ปี)',
                  prefixIcon: const Icon(Icons.cake),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              
              // 🌟 น้ำหนัก และ ส่วนสูง ให้อยู่คู่กัน
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'น้ำหนัก (กก.)',
                        prefixIcon: const Icon(Icons.monitor_weight),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'ส่วนสูง (ซม.)',
                        prefixIcon: const Icon(Icons.height),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🌟 โรคประจำตัว
              TextFormField(
                controller: _diseaseController,
                decoration: InputDecoration(
                  labelText: 'โรคประจำตัว / อาการแพ้ (ถ้ามี)',
                  prefixIcon: const Icon(Icons.medical_information),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: 'เช่น ความดัน, เบาหวาน, แพ้ถั่ว',
                ),
              ),
              const SizedBox(height: 16),
              
              // 🌟 เป้าหมายสุขภาพ (Dropdown)
              DropdownButtonFormField<String>(
                value: _selectedGoal,
                decoration: InputDecoration(
                  labelText: 'เป้าหมายสุขภาพ',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _goalOptions.map((String goal) {
                  return DropdownMenuItem<String>(
                    value: goal,
                    child: Text(goal),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedGoal = newValue;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}