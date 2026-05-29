import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  // 🌟 ฟังก์ชัน Login (เช็คและสร้างข้อมูลเริ่มต้นถ้ายังไม่มี)
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('กรุณากรอกข้อมูลให้ครบ');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // ถ้าไม่มีข้อมูลใน Firestore ให้สร้างใหม่พร้อม "ค่าเริ่มต้นสำหรับหน้าโปรไฟล์"
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'email': email,
            'displayName': email.split('@')[0],
            'status': 'active',
            'warnCount': 0,
            'isOnline': true,
            'createdAt': FieldValue.serverTimestamp(),
            // 👇 ข้อมูลตั้งต้นเพื่อไม่ให้หน้าโปรไฟล์บัคหรือหายไป
            'profileImageUrl': '',
            'bio': 'ยังไม่มีคำแนะนำตัว',
            'weight': 0,
            'height': 0,
            'disease': 'ไม่มี',
            'gender': 'ไม่ระบุ',
            'age': 0,
          });
        } else {
          // ถ้ามีข้อมูลอยู่แล้ว แค่อัปเดตสถานะ Online
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).update({
            'isOnline': true,
          });
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Login ไม่สำเร็จ');
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 🌟 ฟังก์ชัน Register (บันทึกข้อมูลผู้ใช้ใหม่พร้อมค่าโปรไฟล์เริ่มต้น)
  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('กรุณากรอกข้อมูลให้ครบ');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // สร้างข้อมูลผู้ใช้ใหม่พร้อม "ค่าเริ่มต้นสำหรับหน้าโปรไฟล์"
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'displayName': email.split('@')[0], 
          'status': 'active', 
          'warnCount': 0,
          'isOnline': true,
          'createdAt': FieldValue.serverTimestamp(),
          // 👇 ข้อมูลตั้งต้นเพื่อไม่ให้หน้าโปรไฟล์บัคหรือหายไป
          'profileImageUrl': '',
          'bio': 'ยังไม่มีคำแนะนำตัว',
          'weight': 0,
          'height': 0,
          'disease': 'ไม่มี',
          'gender': 'ไม่ระบุ',
          'age': 0,
        });
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'สมัครสมาชิกไม่สำเร็จ');
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration customInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 50,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'ยินดีต้อนรับ',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เข้าสู่ระบบหรือสมัครสมาชิกเพื่อจัดการเมนูอาหารของคุณ',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        color: Colors.black.withOpacity(0.06),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: customInputDecoration(
                          label: 'Email',
                          icon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: customInputDecoration(
                          label: 'Password',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: isLoading ? null : register,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Food App',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}