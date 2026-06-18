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
  // 🌟 ตัวแปรดึงรายชื่อโรคจาก Firestore
  List<String> diseaseOptions = [];
  bool isLoadingDiseases = true; 

  final List<String> goalOptions = ['ลดน้ำหนัก', 'เพิ่มกล้ามเนื้อ', 'รักษาสุขภาพ', 'อาหารคลีน', 'มังสวิรัติ'];

  List<String> selectedDiseases = [];
  List<String> selectedGoals = [];

  // 🌟 ตัวแปรสำหรับระบบรู้ใจ
  bool usePersonalizedProfile = true; 
  List<String> userFavoriteCategories = []; 
  bool isLoadingPreferences = true;

  @override
  void initState() {
    super.initState();
    _loadDiseasesFromFirestore(); 
    _analyzeUserPreferences(); 
  }

  Future<void> _loadDiseasesFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('diseases').get();
      
      List<String> loadedDiseases = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase();
        
        if (status != 'pending' && status != 'rejected') {
          final String name = data['name'] ?? '';
          if (name.isNotEmpty && !loadedDiseases.contains(name)) {
            loadedDiseases.add(name);
          }
        }
      }

      setState(() {
        diseaseOptions = loadedDiseases;
        isLoadingDiseases = false; 
      });
      
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงข้อมูลโรค: $e');
      setState(() {
        diseaseOptions = ['ความดัน', 'เบาหวาน', 'ไขมันในเลือด', 'โรคหัวใจ', 'โรคไต'];
        isLoadingDiseases = false;
      });
    }
  }

  Future<void> _analyzeUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoadingPreferences = false);
      return;
    }

    try {
      final favSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (favSnapshot.docs.isEmpty) {
        setState(() => isLoadingPreferences = false);
        return;
      }

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

      var sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)); 

      setState(() {
        userFavoriteCategories = sortedCategories.take(3).map((e) => e.key).toList();
        isLoadingPreferences = false;
      });
      
    } catch (e) {
      print('เกิดข้อผิดพลาดในการวิเคราะห์พฤติกรรม: $e');
      setState(() => isLoadingPreferences = false);
    }
  }

  bool isSmartMatch(String word1, String word2) {
    String clean1 = word1.replaceAll('โรค', '').trim().toLowerCase();
    String clean2 = word2.replaceAll('โรค', '').trim().toLowerCase();
    if (clean1.isEmpty || clean2.isEmpty) return false;
    return clean1.contains(clean2) || clean2.contains(clean1);
  }

  // ==========================================
  // 🌟 ฟังก์ชันสร้าง Dropdown แบบให้แท็กอยู่ด้านในกล่อง
  // ==========================================
  Widget buildMultiSelectDropdown({
    required String hint,
    required List<String> options,
    required List<String> selectedList,
    required Color activeColor,
  }) {
    List<String> availableOptions = options.where((item) => !selectedList.contains(item)).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ป้ายแท็ก (Chips) ของสิ่งที่เลือกไปแล้ว (อยู่ข้างในกล่อง)
          if (selectedList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedList.map((selectedItem) {
                  return InputChip(
                    label: Text(selectedItem),
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    backgroundColor: activeColor,
                    deleteIconColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: activeColor), // ลบขอบดำ
                    ),
                    onDeleted: () {
                      setState(() {
                        selectedList.remove(selectedItem);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            
          // 2. ช่อง Dropdown (ถ้ามีแท็กแล้วจะยุบขนาดให้เล็กลง)
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              isDense: selectedList.isNotEmpty, // ทำให้ dropdown เล็กลงเมื่อมีแท็ก เพื่อไม่ให้กล่องสูงเกิน
              hint: Text(
                selectedList.isEmpty ? hint : 'เลือกเพิ่ม...', 
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)
              ),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              value: null, 
              items: availableOptions.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedList.add(newValue);
                  });
                }
              },
            ),
          ),
        ],
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
                
                isLoadingDiseases 
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : diseaseOptions.isEmpty 
                    ? const Text('ไม่พบข้อมูลโรค', style: TextStyle(color: Colors.grey))
                    : buildMultiSelectDropdown(
                        hint: 'กดเพื่อเลือกโรคประจำตัว...',
                        options: diseaseOptions,
                        selectedList: selectedDiseases,
                        activeColor: Colors.redAccent,
                      ),
                
                const SizedBox(height: 16),
                
                const Text('🎯 เป้าหมายสุขภาพ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                
                buildMultiSelectDropdown(
                  hint: 'กดเพื่อเลือกเป้าหมายสุขภาพ...',
                  options: goalOptions,
                  selectedList: selectedGoals,
                  activeColor: Colors.green,
                ),

                const SizedBox(height: 16),

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
                          Text('แนะนำเมนูจากความชอบ', 
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
                        double matchScore = 0; 
                        int totalConditions = selectedDiseases.length + selectedGoals.length;
                        
                        if (totalConditions == 0 && usePersonalizedProfile) {
                          totalConditions = 1; 
                        }

                        for (var d in selectedDiseases) {
                          if (menu.suitableForDisease.any((md) => isSmartMatch(md, d))) matchScore += 1;
                        }
                        for (var g in selectedGoals) {
                          if (menu.suitableForGoal.any((mg) => isSmartMatch(mg, g))) matchScore += 1;
                        }

                        if (usePersonalizedProfile && userFavoriteCategories.isNotEmpty) {
                          if (userFavoriteCategories.contains(menu.category)) {
                            matchScore += 0.5;
                          }
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