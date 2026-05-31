import 'dart:math'; // 🌟 นำเข้า dart:math สำหรับฟังก์ชันสุ่ม
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'menu_model.dart';
import 'menu_detail_page.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  Future<List<MenuModel>> _fetchFavoriteMenus(List<String> menuIds) async {
    List<MenuModel> loadedMenus = [];
    for (String id in menuIds) {
      try {
        final doc = await FirebaseFirestore.instance.collection('menus').doc(id).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          // 🌟 เช็คว่าสถานะต้องไม่ใช่ deleted
          final status = data['status']?.toString().toLowerCase() ?? 'published';
          if (status != 'deleted') {
            loadedMenus.add(MenuModel.fromMap(doc.id, data));
          }
        }
      } catch (e) {
        // ข้ามเมนูที่ถูกลบไปแล้วหรือเกิด Error
      }
    }
    return loadedMenus;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('เมนูโปรด')), 
        body: const Center(child: Text('กรุณาเข้าสู่ระบบ'))
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('favorites').where('userId', isEqualTo: user.uid).snapshots(),
      builder: (context, favSnapshot) {
        
        if (favSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('เมนูโปรดของฉัน'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
            backgroundColor: const Color(0xFFF6F7FB),
            body: const Center(child: CircularProgressIndicator())
          );
        }

        if (!favSnapshot.hasData || favSnapshot.data!.docs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('เมนูโปรดของฉัน'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
            backgroundColor: const Color(0xFFF6F7FB),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('คุณยังไม่มีเมนูโปรด', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            ),
          );
        }

        final menuIds = favSnapshot.data!.docs.map((doc) => doc['menuId'] as String).toList();

        return FutureBuilder<List<MenuModel>>(
          future: _fetchFavoriteMenus(menuIds),
          builder: (context, menuSnapshot) {
            
            if (menuSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(title: const Text('เมนูโปรดของฉัน'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
                backgroundColor: const Color(0xFFF6F7FB),
                body: const Center(child: CircularProgressIndicator())
              );
            }

            final menus = menuSnapshot.data ?? [];

            return Scaffold(
              backgroundColor: const Color(0xFFF6F7FB),
              appBar: AppBar(title: const Text('เมนูโปรดของฉัน'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
              
              // 🌟 เรียกใช้ปุ่มสุ่มเมนูที่แยก Widget ไว้ด้านล่างสุด
              floatingActionButton: menus.isNotEmpty ? RandomMenuButton(menus: menus) : null,

              body: menus.isEmpty 
                ? const Center(child: Text('ไม่พบข้อมูลเมนู'))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80), 
                    itemCount: menus.length,
                    itemBuilder: (context, index) {
                      final menu = menus[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: menu.imageUrl.isNotEmpty && menu.imageUrl.startsWith('http')
                                ? Image.network(menu.imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey.shade200, width: 60, height: 60, child: const Icon(Icons.fastfood)))
                                : Container(color: Colors.grey.shade200, width: 60, height: 60, child: const Icon(Icons.fastfood)),
                          ),
                          title: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text('${menu.category} • ${menu.calories} kcal'),
                          trailing: const Icon(Icons.favorite, color: Colors.red),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MenuDetailPage(menu: menu)),
                            );
                          },
                        ),
                      );
                    },
                  ),
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// 🌟 วิดเจ็ตปุ่มสุ่มเมนู (แก้ไขปัญหา Layout ค้างจนจอดำจางเรียบร้อยแล้ว)
// ============================================================================
class RandomMenuButton extends StatefulWidget {
  final List<MenuModel> menus;
  const RandomMenuButton({Key? key, required this.menus}) : super(key: key);

  @override
  State<RandomMenuButton> createState() => _RandomMenuButtonState();
}

class _RandomMenuButtonState extends State<RandomMenuButton> {
  
  void _showRandomDialog() {
    final random = Random();
    MenuModel selectedMenu = widget.menus[random.nextInt(widget.menus.length)];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext innerContext, StateSetter setDialogState) {
            
            final String imgUrl = selectedMenu.imageUrl.toString();
            final String name = selectedMenu.name.toString().isNotEmpty ? selectedMenu.name.toString() : 'ไม่มีชื่อเมนู';
            final String cal = selectedMenu.calories.toString();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.all(20),
              title: const Text(
                '🎉 มื้อนี้กินนี่ละกัน!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              content: SizedBox(
                width: 300, // 🌟 กำหนดความกว้างที่แน่นอนให้กับกล่อง เพื่อแก้ปัญหาจอดำวาด UI ไม่ขึ้น
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // แสดงรูปภาพอาหาร
                    if (imgUrl.isNotEmpty && imgUrl.startsWith('http'))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imgUrl,
                          height: 150,
                          width: 260, // 🌟 ใช้ขนาดแบบระบุตัวเลขแทนอินฟินิตี้
                          fit: BoxFit.cover,
                          errorBuilder: (c, error, stackTrace) => 
                            const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                        ),
                      )
                    else
                      const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                    
                    const SizedBox(height: 16),
                    
                    // แสดงชื่ออาหาร
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // แสดงแคลอรี่
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🔥 $cal kcal',
                        style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                // ปุ่มกดสุ่มใหม่ภายในกล่อง
                TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      selectedMenu = widget.menus[random.nextInt(widget.menus.length)];
                    });
                  },
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  label: const Text('สุ่มใหม่', style: TextStyle(color: Colors.grey)),
                ),
                // ปุ่มกดเพื่อไปดูวิธีทำ
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext); // ปิดหน้าต่างโชว์ผลลัพธ์สุ่ม
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => MenuDetailPage(menu: selectedMenu)),
                    );
                  },
                  child: const Text('ดูวิธีทำ! 🍳', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _showRandomDialog,
      backgroundColor: Colors.orange,
      icon: const Icon(Icons.casino, color: Colors.white),
      label: const Text('สุ่มเมนู!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}