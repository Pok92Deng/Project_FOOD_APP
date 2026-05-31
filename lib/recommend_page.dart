import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'menu_model.dart';
import 'menu_detail_page.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final List<String> diseaseOptions = [
    'ความดัน', 'เบาหวาน', 'ไขมันในเลือด', 'โรคหัวใจ', 'หลอดเลือดสมอง', 
    'โรคไต', 'โรคมะเร็ง', 'โรคอ้วน', 'ภูมิแพ้', 'หอบหืด', 'โรคปอด', 'เกาต์', 'ไทรอยด์'
  ];
  final List<String> goalOptions = ['ลดน้ำหนัก', 'เพิ่มกล้ามเนื้อ', 'รักษาสุขภาพ', 'อาหารคลีน', 'คีโต', 'มังสวิรัติ'];

  List<String> selectedDiseases = [];
  List<String> selectedGoals = [];

  // 🌟 ตัวแปรสำหรับระบบรู้ใจ (Personalized)
  bool usePersonalizedProfile = true; // เปิดโหมดดึงข้อมูลโปรไฟล์โดยปริยาย
  List<String> userFavoriteCategories = []; // เก็บหมวดหมู่ที่ผู้ใช้ชอบ
  bool isLoadingPreferences = true;

  @override
  void initState() {
    super.initState();
    _analyzeUserPreferences(); // สั่งให้ระบบวิเคราะห์ความชอบทันทีที่เปิดหน้านี้
  }

  // ==========================================
  // 🧠 ระบบวิเคราะห์พฤติกรรมผู้ใช้ (แอบดูว่าชอบกดหัวใจเมนูแบบไหน)
  // ==========================================
  Future<void> _analyzeUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoadingPreferences = false);
      return;
    }

    try {
      // 1. ดึงรายการเมนูที่ผู้ใช้เคยกดหัวใจไว้
      final favSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (favSnapshot.docs.isEmpty) {
        setState(() => isLoadingPreferences = false);
        return;
      }

      // 2. ดึงข้อมูลเมนูแบบเต็มเพื่อดูหมวดหมู่ (Category)
      Map<String, int> categoryCount = {};
      final menuIds = favSnapshot.docs.map((doc) => doc['menuId'] as String).toList();

      for (String id in menuIds) {
        final menuDoc = await FirebaseFirestore.instance.collection('menus').doc(id).get();
        if (menuDoc.exists && menuDoc.data() != null) {
          final data = menuDoc.data()!;
          final String category = data['category']?.toString() ?? '';
          
          if (category.isNotEmpty) {
            categoryCount[category] = (categoryCount[category] ?? 0) + 1;
          }
        }
      }

      // 3. คัดเลือกหมวดหมู่ที่ชอบมากที่สุด (มีคะแนนโหวตสูงสุด)
      var sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)); // เรียงจากมากไปน้อย

      setState(() {
        // เก็บหมวดหมู่สุดโปรดไว้ 3 อันดับแรก
        userFavoriteCategories = sortedCategories.take(3).map((e) => e.key).toList();
        isLoadingPreferences = false;
      });
      
      print('🌟 หมวดหมู่ที่ผู้ใช้ชอบมากที่สุด: $userFavoriteCategories');

    } catch (e) {
      print('เกิดข้อผิดพลาดในการวิเคราะห์พฤติกรรม: $e');
      setState(() => isLoadingPreferences = false);
    }
  }

  // 🧠 ฟังก์ชันเทียบคำอัจฉริยะ (Fuzzy Match)
  bool isSmartMatch(String word1, String word2) {
    String clean1 = word1.replaceAll('โรค', '').trim().toLowerCase();
    String clean2 = word2.replaceAll('โรค', '').trim().toLowerCase();
    if (clean1.isEmpty || clean2.isEmpty) return false;
    return clean1.contains(clean2) || clean2.contains(clean1);
  }

  // ฟังก์ชันสร้างปุ่มเลือกแบบ "เลื่อนแนวนอน"
  Widget buildHorizontalFilterChips(List<String> options, List<String> selectedList, Color activeColor) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedList.contains(option);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(option),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey.shade100,
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
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('แนะนำอาหารอัจฉริยะ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ==========================================
          // ท่อนบน: ส่วนเลือกโรค, เป้าหมาย และ สวิตช์ความชอบ
          // ==========================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🩺 โรคประจำตัวของคุณ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                buildHorizontalFilterChips(diseaseOptions, selectedDiseases, Colors.redAccent),
                
                const SizedBox(height: 16),
                
                const Text('🎯 เป้าหมายสุขภาพ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                buildHorizontalFilterChips(goalOptions, selectedGoals, Colors.green),

                const SizedBox(height: 16),

                // 🌟 เพิ่มสวิตช์ "โหมดรู้ใจ (Personalized Profile)"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.purple.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text('แนะนำเมนูจากความชอบของคุณ', 
                            style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Switch(
                        value: usePersonalizedProfile,
                        activeColor: Colors.purple,
                        onChanged: (value) {
                          setState(() {
                            usePersonalizedProfile = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // ==========================================
          // ท่อนล่าง: รายการเมนู
          // ==========================================
          Expanded(
            child: (selectedDiseases.isEmpty && selectedGoals.isEmpty && !usePersonalizedProfile)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('กรุณาเลือกเงื่อนไขด้านบน\nหรือเปิดโหมดแนะนำจากความชอบ', 
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('menus').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting || isLoadingPreferences) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
                      }

                      final menus = snapshot.data?.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status']?.toString().toLowerCase() ?? 'published';
                        return status != 'deleted';
                      }).map((doc) => MenuModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList() ?? [];

                      List<Map<String, dynamic>> recommendedMenus = [];

                      for (var menu in menus) {
                        double matchScore = 0; // เปลี่ยนเป็น double เพื่อเก็บคะแนนย่อย
                        int totalConditions = selectedDiseases.length + selectedGoals.length;
                        
                        // ถ้าไม่ได้เลือกอะไรเลย แต่เปิดโหมดความชอบ ให้ฐานคะแนนเป็น 1 เพื่อให้ระบบคำนวณได้
                        if (totalConditions == 0 && usePersonalizedProfile) {
                          totalConditions = 1; 
                        }

                        // 1. ตรวจสอบเงื่อนไขสุขภาพหลัก (โรคและเป้าหมาย)
                        for (var d in selectedDiseases) {
                          if (menu.suitableForDisease.any((md) => isSmartMatch(md, d))) matchScore += 1;
                        }
                        for (var g in selectedGoals) {
                          if (menu.suitableForGoal.any((mg) => isSmartMatch(mg, g))) matchScore += 1;
                        }

                        // 🌟 2. ให้คะแนนโบนัสพิเศษจาก Profile ความชอบ (ถ้าเปิดสวิตช์อยู่)
                        if (usePersonalizedProfile && userFavoriteCategories.isNotEmpty) {
                          if (userFavoriteCategories.contains(menu.category)) {
                            // ให้คะแนนโบนัส 0.5 แต้ม (ไม่เยอะเกินไปจนกลบเงื่อนไขสุขภาพ แต่มากพอที่จะดันเมนูนี้ขึ้นบน)
                            matchScore += 0.5;
                          }
                        }

                        // ถ้ามีคะแนน (ไม่ว่าจะจากสุขภาพหรือความชอบ) ก็เอามาแสดง
                        if (matchScore > 0) {
                          int matchPercentage = ((matchScore / totalConditions) * 100).toInt();
                          recommendedMenus.add({
                            'menu': menu,
                            'score': matchScore,
                            'percentage': matchPercentage > 100 ? 100 : matchPercentage,
                          });
                        }
                      }

                      // เรียงลำดับตามคะแนนความเหมาะสม (ใครคะแนนสูงสุดอยู่บนสุด)
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
                          
                          // เช็คว่าเป็นเมนูที่ได้โบนัสจากความชอบหรือไม่
                          final bool isFavoriteCategory = usePersonalizedProfile && userFavoriteCategories.contains(menu.category);

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
                                      
                                      // ป้ายเปอร์เซ็นต์ความเหมาะสม
                                      Positioned(
                                        top: 12, right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: percentage >= 100 ? Colors.green : Colors.orange,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.white, size: 14),
                                              const SizedBox(width: 4),
                                              Text('ตรงกับคุณ $percentage%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // 🌟 ป้ายบอกว่านี่คือเมนูที่ตรงกับความชอบของผู้ใช้
                                      if (isFavoriteCategory)
                                        Positioned(
                                          top: 12, left: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                                                SizedBox(width: 4),
                                                Text('เมนูสไตล์ที่คุณชอบ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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