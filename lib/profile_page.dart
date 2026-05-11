import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final diseaseController = TextEditingController();
  final goalController = TextEditingController();
  final preferenceController = TextEditingController();

  bool isLoading = false;

  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': nameController.text.trim(),
        'age': ageController.text.trim(),
        'disease': diseaseController.text.trim(),
        'goal': goalController.text.trim(),
        'preference': preferenceController.text.trim(),
      });

      showMessage('บันทึกสำเร็จ');
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      nameController.text = data['name'] ?? '';
      ageController.text = data['age'] ?? '';
      diseaseController.text = data['disease'] ?? '';
      goalController.text = data['goal'] ?? '';
      preferenceController.text = data['preference'] ?? '';
    }
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
    ageController.dispose();
    diseaseController.dispose();
    goalController.dispose();
    preferenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('โปรไฟล์'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 14),
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
                    decoration: inputStyle('ชื่อ', Icons.person_outline),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: inputStyle('อายุ', Icons.cake_outlined),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: diseaseController,
                    decoration:
                        inputStyle('โรคประจำตัว', Icons.health_and_safety),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: goalController,
                    decoration:
                        inputStyle('เป้าหมายสุขภาพ', Icons.flag_outlined),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: preferenceController,
                    decoration:
                        inputStyle('ความชอบอาหาร', Icons.favorite_outline),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text('บันทึกข้อมูล'),
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