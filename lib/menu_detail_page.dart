import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'menu_model.dart';
import 'chat_room_page.dart'; // หากคุณใช้หน้าแชทชื่ออื่น อย่าลืมเปลี่ยนชื่อไฟล์ตรงนี้นะครับ

class MenuDetailPage extends StatefulWidget {
  final MenuModel menu;

  const MenuDetailPage({super.key, required this.menu});

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  bool isFavorite = false;
  String? favoriteDocId;

  int _selectedRating = 5; 
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingReview = false;

  // 🌟 ตัวแปรสำหรับเก็บข้อมูลแจ้งเตือนสุขภาพ
  bool _isLoadingHealthCheck = true;
  List<String> _healthWarnings = [];
  String _userDiseaseName = '';

  @override
  void initState() {
    super.initState();
    checkFavorite();
    _checkHealthSafety(); // 🌟 เรียกใช้ฟังก์ชันตรวจสอบสุขภาพตอนเปิดหน้า
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // 🌟 ฟังก์ชันอัจฉริยะ ตรวจสอบความปลอดภัยของเมนูอาหารกับโรคผู้ใช้
  Future<void> _checkHealthSafety() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingHealthCheck = false);
      return;
    }

    try {
      // 1. ดึงข้อมูลโปรไฟล์ผู้ใช้เพื่อดูว่าป่วยเป็นโรคอะไร
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        if (mounted) setState(() => _isLoadingHealthCheck = false);
        return;
      }

      final userData = userDoc.data()!;
      final userDisease = userData['disease']?.toString() ?? userData['healthCondition']?.toString() ?? '';

      if (userDisease.isEmpty || userDisease == 'ไม่มี') {
        if (mounted) setState(() => _isLoadingHealthCheck = false);
        return; // สุขภาพแข็งแรงดี ไม่ต้องเตือน
      }

      // 2. ไปดึงกฎของโรค (Rules) จากตาราง diseases ที่แอดมินตั้งไว้
      final diseasesSnap = await FirebaseFirestore.instance.collection('diseases').get();
      Map<String, dynamic>? targetRules;
      String matchedDiseaseName = '';

      for (var doc in diseasesSnap.docs) {
        final diseaseName = doc['name'].toString();
        
        // จำลองระบบ Fuzzy Match (เทียบคำคล้าย) แบบเว็บแอดมิน
        final cleanUserDisease = userDisease.replaceAll('โรค', '').trim().toLowerCase();
        final cleanDbDisease = diseaseName.replaceAll('โรค', '').trim().toLowerCase();

        if (cleanUserDisease.isNotEmpty && cleanDbDisease.isNotEmpty &&
            (cleanUserDisease.contains(cleanDbDisease) || cleanDbDisease.contains(cleanUserDisease))) {
          targetRules = doc['rules'] as Map<String, dynamic>?;
          matchedDiseaseName = diseaseName;
          break;
        }
      }

      // 3. เทียบโภชนาการเมนู กับ กฎของโรค
      if (targetRules != null) {
        List<String> warnings = [];
        final menu = widget.menu;

        if (targetRules['sodium'] != null && menu.sodium > targetRules['sodium']) {
          warnings.add('⚠️ โซเดียมสูงเกินเกณฑ์ (${menu.sodium} / ${targetRules['sodium']} mg)');
        }
        if (targetRules['sugar'] != null && menu.carb > targetRules['sugar']) {
          warnings.add('⚠️ คาร์บ/น้ำตาลสูงเกินเกณฑ์ (${menu.carb} / ${targetRules['sugar']} g)');
        }
        if (targetRules['fat'] != null && menu.fat > targetRules['fat']) {
          warnings.add('⚠️ ไขมันสูงเกินเกณฑ์ (${menu.fat} / ${targetRules['fat']} g)');
        }
        if (targetRules['protein'] != null && menu.protein > targetRules['protein']) {
          warnings.add('⚠️ โปรตีนสูงเกินเกณฑ์ (${menu.protein} / ${targetRules['protein']} g)');
        }
        if (targetRules['calories'] != null && menu.calories > targetRules['calories']) {
          warnings.add('⚠️ พลังงานสูงเกินเกณฑ์ (${menu.calories} / ${targetRules['calories']} kcal)');
        }

        if (warnings.isNotEmpty) {
          if (mounted) {
            setState(() {
              _healthWarnings = warnings;
              _userDiseaseName = matchedDiseaseName;
            });
          }
        }
      }
    } catch (e) {
      print("Error checking health safety: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingHealthCheck = false);
      }
    }
  }

  Future<void> _startChat(BuildContext context, String ownerEmail) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนทักแชท')));
      return;
    }
    
    final myEmail = currentUser.email!;
    if (myEmail == ownerEmail) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('คุณไม่สามารถทักแชทตัวเองได้')));
      return;
    }

    final chatId1 = '${myEmail}_$ownerEmail';
    final chatId2 = '${ownerEmail}_$myEmail';

    final doc1 = await FirebaseFirestore.instance.collection('chats').doc(chatId1).get();
    final doc2 = await FirebaseFirestore.instance.collection('chats').doc(chatId2).get();

    String targetChatId;
    if (doc1.exists) {
      targetChatId = chatId1;
    } else if (doc2.exists) {
      targetChatId = chatId2;
    } else {
      targetChatId = chatId1;
    }

    await FirebaseFirestore.instance.collection('chats').doc(targetChatId).set({
      'participants': [myEmail, ownerEmail],
    }, SetOptions(merge: true));

    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomPage(
      chatId: targetChatId,
      receiverEmail: ownerEmail,
    )));
  }

  Future<void> checkFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .where('menuId', isEqualTo: widget.menu.id)
        .get();

    if (snapshot.docs.isNotEmpty && mounted) {
      setState(() {
        isFavorite = true;
        favoriteDocId = snapshot.docs.first.id;
      });
    }
  }

  Future<void> toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (isFavorite && favoriteDocId != null) {
      await FirebaseFirestore.instance.collection('favorites').doc(favoriteDocId).delete();
      if (mounted) setState(() { isFavorite = false; favoriteDocId = null; });
    } else {
      final doc = await FirebaseFirestore.instance.collection('favorites').add({
        'userId': user.uid,
        'menuId': widget.menu.id,
        'createdAt': Timestamp.now(),
      });
      if (mounted) setState(() { isFavorite = true; favoriteDocId = doc.id; });
    }
  }

  Future<void> _shareToCommunity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final TextEditingController captionController = TextEditingController();
    bool isSharing = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('แชร์ลงชุมชน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'เขียนแคปชันบอกเพื่อนๆ หน่อย...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                maxLines: 3,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: isSharing ? null : () async {
                    setStateDialog(() => isSharing = true);
                    try {
                      await FirebaseFirestore.instance.collection('community_posts').add({
                        'menuId': widget.menu.id,
                        'userId': user.uid,
                        'userEmail': user.email ?? 'ไม่ระบุตัวตน',
                        'caption': captionController.text.trim(),
                        'likes': [], 
                        'createdAt': Timestamp.now(),
                      });
                      if (!mounted) return;
                      Navigator.pop(dialogContext); 
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('แชร์เมนูสำเร็จ!'), backgroundColor: Colors.green));
                    } catch (e) {
                      setStateDialog(() => isSharing = false);
                    }
                  },
                  child: isSharing ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('แชร์เลย', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmittingReview = true);

    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'menuId': widget.menu.id,
        'userId': user.uid,
        'userEmail': user.email ?? 'ไม่ระบุ',
        'rating': _selectedRating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      setState(() {
        _selectedRating = 5;
        _isSubmittingReview = false;
      });
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งรีวิวสำเร็จ!'), backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _isSubmittingReview = false);
    }
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget buildInfoCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('รายละเอียดเมนู'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _shareToCommunity,
            icon: const Icon(Icons.ios_share, color: Colors.blue),
          ),
          IconButton(
            onPressed: toggleFavorite,
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
          ),
        ],
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: menu.imageUrl.isNotEmpty
                ? Image.network(menu.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 80)))
                : Container(color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 80)),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Text(menu.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
                    
                    if (currentUserEmail != null && currentUserEmail != menu.authorEmail)
                      ElevatedButton.icon(
                        onPressed: () => _startChat(context, menu.authorEmail),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white),
                        label: const Text('ทักแชท', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 0,
                        ),
                      )
                  ],
                ),
                
                const SizedBox(height: 6),
                Text('โดย: ${menu.authorEmail}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 12),
                
                Text(menu.description, style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.5)),
                
                // ==========================================
                // 🌟 กล่องแจ้งเตือนสุขภาพ (แสดงเฉพาะเมื่อมีความเสี่ยง)
                // ==========================================
                if (_isLoadingHealthCheck)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                if (!_isLoadingHealthCheck && _healthWarnings.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.red.shade100, blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_rounded, color: Colors.red.shade800, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'แจ้งเตือนผู้ป่วย $_userDiseaseName',
                                style: TextStyle(color: Colors.red.shade900, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Colors.white, thickness: 1.5),
                        ),
                        Text(
                          'เมนูนี้มีสารอาหารบางอย่างที่เกินเกณฑ์ควบคุมของคุณ:',
                          style: TextStyle(color: Colors.red.shade900, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        ..._healthWarnings.map((warn) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(warn, style: TextStyle(color: Colors.red.shade700, fontSize: 14, fontWeight: FontWeight.w600)),
                        )),
                      ],
                    ),
                  ),
                
                if (!_isLoadingHealthCheck && _healthWarnings.isEmpty && _userDiseaseName.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(child: Text('เมนูนี้อยู่ในเกณฑ์ปลอดภัยสำหรับผู้ป่วย $_userDiseaseName ครับ 🥗', style: const TextStyle(color: Colors.green))),
                      ],
                    ),
                  ),
                // ==========================================

                const Divider(height: 20),
                
                buildSectionTitle('ข้อมูลโภชนาการ'),
                buildInfoCard(title: 'พลังงาน', value: '${menu.calories} kcal', icon: Icons.local_fire_department, color: Colors.orange),
                buildInfoCard(title: 'โปรตีน', value: '${menu.protein} g', icon: Icons.fitness_center, color: Colors.blue),
                buildInfoCard(title: 'คาร์บ', value: '${menu.carb} g', icon: Icons.rice_bowl, color: Colors.brown),
                buildInfoCard(title: 'ไขมัน', value: '${menu.fat} g', icon: Icons.opacity, color: Colors.amber.shade700),
                buildInfoCard(title: 'โซเดียม', value: '${menu.sodium} mg', icon: Icons.science, color: Colors.grey.shade600),
                
                buildSectionTitle('ส่วนผสมและวัตถุดิบ'),
                ...menu.ingredients.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const Icon(Icons.check_circle, size: 18, color: Colors.teal),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 15))),
                  ]),
                )),
                
                buildSectionTitle('ขั้นตอนการทำ'),
                ...menu.steps.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 10, backgroundColor: Colors.green, child: Text('${entry.key + 1}', style: const TextStyle(fontSize: 12, color: Colors.white))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 15))),
                    ],
                  ),
                )),
                
                const Divider(height: 40, thickness: 1),

                buildSectionTitle('รีวิวและความคิดเห็น'),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ให้คะแนนเมนูนี้:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              index < _selectedRating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 28,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedRating = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: 'เขียนรีวิวของคุณ...',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: _isSubmittingReview 
                              ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : IconButton(
                                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                                  onPressed: _submitReview,
                                ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('menuId', isEqualTo: widget.menu.id)
                      .snapshots(), 
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Text('เกิดข้อผิดพลาดในการโหลดรีวิว');
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    var docs = snapshot.data?.docs ?? [];
                    
                    docs.sort((a, b) {
                      final timeA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      final timeB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      if (timeA == null || timeB == null) return 0;
                      return timeB.compareTo(timeA);
                    });

                    if (docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text('ยังไม่มีรีวิว เป็นคนแรกที่รีวิวสิ!', style: TextStyle(color: Colors.grey.shade500)),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final rating = data['rating'] ?? 5;
                        final comment = data['comment'] ?? '';
                        final email = data['userEmail'] ?? 'User';
                        final username = email.split('@')[0];

                        final Timestamp? t = data['createdAt'];
                        final dateStr = t != null 
                            ? '${t.toDate().day}/${t.toDate().month}/${t.toDate().year + 543}' 
                            : 'เมื่อกี้';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (i) => Icon(
                                  i < rating ? Icons.star : Icons.star_border,
                                  size: 16, color: Colors.amber,
                                )),
                              ),
                              const SizedBox(height: 8),
                              Text(comment, style: const TextStyle(color: Colors.black87)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}