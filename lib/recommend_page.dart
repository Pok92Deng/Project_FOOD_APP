import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_model.dart';
import 'menu_detail_page.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  // 🌟 อัปเดตรายชื่อ 13 โรคยอดฮิตให้ตรงกับเว็บแอดมิน
  final List<String> diseaseOptions = [
    'ความดัน', 'เบาหวาน', 'ไขมันในเลือด', 'โรคหัวใจ', 'หลอดเลือดสมอง', 
    'โรคไต', 'โรคมะเร็ง', 'โรคอ้วน', 'ภูมิแพ้', 'หอบหืด', 'โรคปอด', 'เกาต์', 'ไทรอยด์'
  ];
  final List<String> goalOptions = ['ลดน้ำหนัก', 'เพิ่มกล้ามเนื้อ', 'รักษาสุขภาพ', 'อาหารคลีน', 'คีโต', 'มังสวิรัติ'];

  List<String> selectedDiseases = [];
  List<String> selectedGoals = [];

  // 🧠 ฟังก์ชันเทียบคำอัจฉริยะ (Fuzzy Match)
  bool isSmartMatch(String word1, String word2) {
    // 1. ตัดคำว่า "โรค" ออก และลบช่องว่างซ้ายขวา
    String clean1 = word1.replaceAll('โรค', '').trim().toLowerCase();
    String clean2 = word2.replaceAll('โรค', '').trim().toLowerCase();
    
    // ถ้าลบแล้วเหลือค่าว่าง ให้ข้ามไป
    if (clean1.isEmpty || clean2.isEmpty) return false;

    // 2. เช็คว่าคำใดคำหนึ่ง ไปซ่อนเป็นส่วนหนึ่งของอีกคำหรือไม่ 
    // (เช่น "ความดันโลหิตสูง" กับ "ความดัน" ก็จะเจอกัน!)
    return clean1.contains(clean2) || clean2.contains(clean1);
  }

  Widget buildFilterChips(List<String> options, List<String> selectedList, Color activeColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedList.contains(option);
        return FilterChip(
          label: Text(option),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: Colors.white,
          selectedColor: activeColor,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isSelected ? activeColor : Colors.grey.shade300),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedList.add(option);
              } else {
                selectedList.remove(option);
              }
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('แนะนำอาหารอัจฉริยะ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🩺 โรคประจำตัวของคุณ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                buildFilterChips(diseaseOptions, selectedDiseases, Colors.redAccent),
                
                const SizedBox(height: 20),
                
                const Text('🎯 เป้าหมายสุขภาพ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                buildFilterChips(goalOptions, selectedGoals, Colors.green),
              ],
            ),
          ),
          
          Expanded(
            child: (selectedDiseases.isEmpty && selectedGoals.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('กรุณาเลือกเงื่อนไขด้านบน\nเพื่อให้ระบบค้นหาเมนูที่เหมาะสมที่สุด', 
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('menus').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
                      }

                      // 🌟 ดักกรองเมนูที่ถูกลบไปแล้วออกจากการแนะนำ
                      final menus = snapshot.data?.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status']?.toString().toLowerCase() ?? 'published';
                        return status != 'deleted';
                      }).map((doc) => MenuModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList() ?? [];

                      List<Map<String, dynamic>> recommendedMenus = [];

                      for (var menu in menus) {
                        int matchScore = 0;
                        int totalConditions = selectedDiseases.length + selectedGoals.length;

                        // 🌟 เรียกใช้ระบบเทียบคำอัจฉริยะ (isSmartMatch) ที่เราสร้างขึ้น
                        for (var d in selectedDiseases) {
                          if (menu.suitableForDisease.any((md) => isSmartMatch(md, d))) matchScore++;
                        }
                        for (var g in selectedGoals) {
                          if (menu.suitableForGoal.any((mg) => isSmartMatch(mg, g))) matchScore++;
                        }

                        if (matchScore > 0) {
                          int matchPercentage = ((matchScore / totalConditions) * 100).toInt();
                          recommendedMenus.add({
                            'menu': menu,
                            'score': matchScore,
                            'percentage': matchPercentage > 100 ? 100 : matchPercentage,
                          });
                        }
                      }

                      recommendedMenus.sort((a, b) => b['score'].compareTo(a['score']));

                      if (recommendedMenus.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('ไม่มีเมนูที่ตรงกับเงื่อนไขของคุณในขณะนี้', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: recommendedMenus.length,
                        itemBuilder: (context, index) {
                          final item = recommendedMenus[index];
                          final MenuModel menu = item['menu'];
                          final int percentage = item['percentage'];

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => MenuDetailPage(menu: menu)));
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: SizedBox(
                                          height: 140, width: double.infinity,
                                          child: menu.imageUrl.isNotEmpty
                                              ? Image.network(menu.imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 50)))
                                              : Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 50)),
                                        ),
                                      ),
                                      Positioned(
                                        top: 12, right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: percentage == 100 ? Colors.green : Colors.orange,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.white, size: 14),
                                              const SizedBox(width: 4),
                                              Text('ตรงกับคุณ $percentage%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(menu.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 6),
                                              Text(menu.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          children: [
                                            const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                                            Text('${menu.calories}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            const Text('kcal', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}