import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_model.dart';
import 'menu_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'ค้นหาเมนู, หมวดหมู่, วัตถุดิบ...',
              border: InputBorder.none, prefixIcon: const Icon(Icons.search, color: Colors.grey),
              hintStyle: TextStyle(color: Colors.grey.shade500),
            ),
            onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menus').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('เกิดข้อผิดพลาด'));

          // 🌟 ดักกรองเมนูที่ถูกลบทิ้งไป
          final menus = snapshot.data?.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status']?.toString().toLowerCase() ?? 'published';
            return status != 'deleted';
          }).map((doc) => MenuModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList() ?? [];

          final filteredMenus = menus.where((menu) {
            if (searchQuery.isEmpty) return true;
            return menu.name.toLowerCase().contains(searchQuery) || 
                   menu.category.toLowerCase().contains(searchQuery) || 
                   menu.ingredients.any((i) => i.toLowerCase().contains(searchQuery));
          }).toList();

          if (filteredMenus.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('ไม่พบผลลัพธ์', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredMenus.length,
            itemBuilder: (context, index) {
              final menu = filteredMenus[index];
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
                  subtitle: Text('${menu.category} • ${menu.calories} kcal', style: TextStyle(color: Colors.green.shade700)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MenuDetailPage(menu: menu)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}