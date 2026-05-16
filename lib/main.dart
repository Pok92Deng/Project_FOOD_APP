import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Healthy Food App',
      theme: ThemeData(
        primarySwatch: Colors.green, // ตั้งโทนสีหลักเป็นสีเขียวให้ดูสุขภาพดี
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    // ใช้ StreamBuilder ดักฟังสถานะการเข้าสู่ระบบตลอดเวลา
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ระหว่างรอโหลดข้อมูล ให้หมุนรอ
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // ถ้ามีข้อมูล User แปลว่าล็อกอินอยู่ ให้ไปหน้า Home
        if (snapshot.hasData) {
          return const HomePage();
        }
        // ถ้าไม่มีข้อมูล แปลว่ายังไม่ล็อกอิน ให้ไปหน้า Login
        return const LoginPage();
      },
    );
  }
}