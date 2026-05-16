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
          loadedMenus.add(MenuModel.fromMap(doc.id, doc.data()!));
        }
      } catch (e) {
        // ข้ามเมนูที่ถูกลบไปแล้ว
      }
    }
    return loadedMenus;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Scaffold(appBar: AppBar(title: const Text('เมนูโปรด')), body: const Center(child: Text('กรุณาเข้าสู่ระบบ')));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('เมนูโปรดของฉัน'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('favorites').where('userId', isEqualTo: user.uid).snapshots(),
        builder: (context, favSnapshot) {
          if (favSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!favSnapshot.hasData || favSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('คุณยังไม่มีเมนูโปรด', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          final menuIds = favSnapshot.data!.docs.map((doc) => doc['menuId'] as String).toList();

          return FutureBuilder<List<MenuModel>>(
            future: _fetchFavoriteMenus(menuIds),
            builder: (context, menuSnapshot) {
              if (menuSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final menus = menuSnapshot.data ?? [];
              if (menus.isEmpty) return const Center(child: Text('ไม่พบข้อมูลเมนู'));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
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
                          // แก้ไขตรงนี้ให้ส่ง menu ไปอย่างถูกต้อง
                          MaterialPageRoute(builder: (context) => MenuDetailPage(menu: menu)),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}