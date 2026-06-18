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
  final _birthDateController = TextEditingController(); // 🌟 เปลี่ยนเป็นตัวรับวันเกิด
  final _weightController = TextEditingController(); 
  final _heightController = TextEditingController(); 
  final _diseaseController = TextEditingController(); 
  
  DateTime? _selectedBirthDate; // 🌟 ตัวแปรเก็บค่าวันเกิดที่เลือกจากปฏิทิน

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
          _weightController.text = data['weight']?.toString() ?? ''; 
          _heightController.text = data['height']?.toString() ?? ''; 
          _diseaseController.text = data['disease'] ?? ''; 
          
          if (data['goal'] != null && _goalOptions.contains(data['goal'])) {
            _selectedGoal = data['goal'];
          }

          // 🌟 ดึงข้อมูลวันเกิดมาแสดง (ถ้ามี)
          if (data.containsKey('birthDate') && data['birthDate'] != null) {
            _selectedBirthDate = (data['birthDate'] as Timestamp).toDate();
            _birthDateController.text = "${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year + 543}"; // โชว์เป็น พ.ศ.
          } else if (data.containsKey('birthYear') && data['birthYear'] != null) {
            // รองรับข้อมูลผู้ใช้เก่าที่เคยมีแค่ birthYear
            _selectedBirthDate = DateTime(data['birthYear'], 1, 1);
            _birthDateController.text = "1/1/${_selectedBirthDate!.year + 543}";
          }
        });
      }
    }
  }

  // 🌟 ฟังก์ชันเปิดปฏิทินเลือกวันเกิด
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(DateTime.now().year - 20), // ค่าเริ่มต้นย้อนไป 20 ปี
      firstDate: DateTime(1900), // เลือกได้ย้อนหลังสุดถึงปี 1900
      lastDate: DateTime.now(), // เลือกได้ถึงแค่วันนี้
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green, // สีหัวปฏิทิน
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = "${picked.day}/${picked.month}/${picked.year + 543}"; // อัปเดตช่องกรอกเป็น พ.ศ.
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุวันเกิดด้วยครับ'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        
        // 🌟 คำนวณอายุเพื่อใช้เป็นข้อมูลอ้างอิงให้ระบบ (คำนวณเป๊ะระดับเดือนและวัน)
        int currentYear = DateTime.now().year;
        int age = currentYear - _selectedBirthDate!.year;
        if (DateTime.now().month < _selectedBirthDate!.month || 
           (DateTime.now().month == _selectedBirthDate!.month && DateTime.now().day < _selectedBirthDate!.day)) {
          age--; // ถ้ายังไม่ถึงวันเกิดในปีนี้ ให้ลบอายุออก 1
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _displayNameController.text.trim(),
          'birthDate': Timestamp.fromDate(_selectedBirthDate!), // 🌟 บันทึกเป็นรูปแบบ Timestamp
          'birthYear': _selectedBirthDate!.year, 
          'age': age, 
          'weight': _weightController.text.trim(),
          'height': _heightController.text.trim(), 
          'disease': _diseaseController.text.trim(),
          'goal': _selectedGoal, 
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลโปรไฟล์สำเร็จ! ✅'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _birthDateController.dispose();
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
              
              // 🌟 ช่องวันเกิด (กดแล้วมีปฏิทินเด้ง)
              TextFormField(
                controller: _birthDateController,
                readOnly: true, // ป้องกันการพิมพ์ตัวเลขมั่วๆ ต้องกดปฏิทินเท่านั้น
                onTap: () => _selectDate(context),
                decoration: InputDecoration(
                  labelText: 'วัน/เดือน/ปีเกิด',
                  prefixIcon: const Icon(Icons.cake, color: Color.fromARGB(255, 0, 0, 0)),
                  suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: 'เลือกวันเกิดของคุณ',
                ),
                validator: (value) => value!.isEmpty ? 'กรุณาเลือกวันเกิด' : null,
              ),
              const SizedBox(height: 16),
              
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