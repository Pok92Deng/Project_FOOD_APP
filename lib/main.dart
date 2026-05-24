import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// นำเข้าหน้าหลักต่างๆ (ตรวจสอบชื่อไฟล์ให้ตรงกับที่คุณมี)
import 'home_page.dart';
import 'login_page.dart'; // หากไฟล์หน้าล็อกอินของคุณชื่ออื่น สามารถแก้ตรงนี้ได้เลยครับ

void main() async {
  // คำสั่งบังคับให้ Flutter เตรียมความพร้อมก่อนรัน Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Healthy Recipe App', // ชื่อแอปพลิเคชัน
      debugShowCheckedModeBanner: false, // 🌟 ปิดป้าย DEBUG สีแดงที่มุมขวาบน
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        fontFamily: 'Roboto', // คุณสามารถเปลี่ยนเป็นฟอนต์ภาษาไทย เช่น 'Sarabun' ได้ถ้าติดตั้งไว้
      ),
      home: const AuthWrapper(), // เรียกใช้ระบบตรวจสอบการล็อกอิน
    );
  }
}

// 🌟 ระบบตรวจสอบสถานะผู้ใช้งาน (Auth Wrapper)
// ถ้าล็อกอินแล้วจะพาไป HomePage อัตโนมัติ ถ้ายังจะพาไป LoginPage
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ระหว่างรอโหลดข้อมูลจาก Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }
        
        // ถ้ามีข้อมูลผู้ใช้ (ล็อกอินแล้ว) ให้ไปหน้าแรก
        if (snapshot.hasData) {
          return const HomePage();
        }
        
        // ถ้าไม่มีข้อมูลผู้ใช้ (ยังไม่ล็อกอิน หรือกด Logout มา) ให้ไปหน้าล็อกอิน
        return const LoginPage(); 
      },
    );
  }
}