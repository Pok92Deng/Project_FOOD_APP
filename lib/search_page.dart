import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'menu_model.dart';
import 'menu_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<MenuModel> _allMenus = []; // เก็บเมนูทั้งหมด
  List<MenuModel> _searchResults = []; // เก็บเมนูที่ค้นหาเจอ (รวมอันที่พิมพ์ผิดนิดหน่อย)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllMenus(); // โหลดเมนูทั้งหมดมารอไว้ก่อน เพื่อให้ค้นหาได้ไวปรู๊ดปร๊าด
  }

  // 🌟 ดึงข้อมูลเมนูทั้งหมดจาก Firebase มาเก็บไว้ในเครื่อง
  Future<void> _loadAllMenus() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('menus')
          .where('status', isNotEqualTo: 'deleted') // ไม่เอาเมนูที่โดนลบ
          .get();

      setState(() {
        _allMenus = snapshot.docs.map((doc) => MenuModel.fromMap(doc.id, doc.data())).toList();
        _searchResults = _allMenus; // ตอนแรกเริ่มให้โชว์ทั้งหมดก่อน
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading menus: $e");
      setState(() => _isLoading = false);
    }
  }

  // 🧠 อัลกอริทึมคณิตศาสตร์ (Levenshtein Distance) คำนวณความเพี้ยนของตัวอักษร
  int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce(min);
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  // 🌟 ฟังก์ชันค้นหาอัจฉริยะ (พิมพ์ถูกก็เจอ พิมพ์ผิดก็หาให้)
  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = _allMenus;
      });
      return;
    }

    final String cleanQuery = query.trim().toLowerCase();
    List<MenuModel> results = [];

    for (var menu in _allMenus) {
      final String cleanName = menu.name.trim().toLowerCase();
      
      // 1. ตรวจสอบแบบตรงตัวก่อน (เผื่อพิมพ์ถูก 100% หรือพิมพ์แค่คำนำหน้า)
      if (cleanName.contains(cleanQuery)) {
        results.add(menu);
        continue; // ถ้าตรงตัวแล้ว ให้ข้ามไปเมนูถัดไปเลย
      }

      // 2. ถ้าไม่ตรงตัว ให้ใช้ "ระบบตรวจจับคำผิด" (Fuzzy Search)
      // เราจะลองเอาคำค้นหา ไปเทียบกับชื่อเมนู ว่าเพี้ยนไปกี่ตัวอักษร
      int distance = levenshteinDistance(cleanQuery, cleanName);
      
      // ถ้ายาวหน่อย อนุโลมให้พิมพ์ผิดได้ 2-3 ตัวอักษร
      int allowedTypos = (cleanQuery.length > 4) ? 2 : 1; 

      // ตรวจสอบทั้งชื่อเมนู หรือหมวดหมู่อาหาร
      if (distance <= allowedTypos || menu.category.toLowerCase().contains(cleanQuery)) {
        results.add(menu);
      }
    }

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // 🌟 กล่องค้นหา
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                onChanged: _performSearch, // พิมพ์ปุ๊บ ค้นหาปั๊บ (Real-time)
                decoration: InputDecoration(
                  hintText: 'ค้นหาเมนูอาหาร (เช่น ข้าวมันไก)...',
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // 🌟 ผลลัพธ์การค้นหา
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('ค้นหา "${_searchController.text}" ไม่พบ', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                              const Text('ลองเปลี่ยนคำค้นหาดูนะครับ', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final menu = _searchResults[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 1,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: menu.imageUrl.isNotEmpty
                                      ? Image.network(menu.imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.fastfood)))
                                      : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.fastfood)),
                                ),
                                title: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Text('${menu.category} • ${menu.calories} kcal', style: TextStyle(color: Colors.green.shade700)),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => MenuDetailPage(menu: menu)));
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}