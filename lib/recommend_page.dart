import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  String userDisease = '';
  String userGoal = '';
  String userPreference = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        userDisease = (data['disease'] ?? '').toString().trim();
        userGoal = (data['goal'] ?? '').toString().trim();
        userPreference = (data['preference'] ?? '').toString().trim();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  int calculateScore(Map<String, dynamic> data) {
    int score = 0;

    final disease = (data['suitableForDisease'] ?? '').toString().trim();
    final goal = (data['suitableForGoal'] ?? '').toString().trim();
    final category = (data['category'] ?? '').toString().trim();

    if (userDisease.isNotEmpty && disease == userDisease) {
      score += 3;
    }

    if (userGoal.isNotEmpty && goal == userGoal) {
      score += 2;
    }

    if (userPreference.isNotEmpty && category == userPreference) {
      score += 1;
    }

    return score;
  }

  String scoreLabel(int score) {
    if (score >= 5) return 'เหมาะมาก';
    if (score >= 3) return 'แนะนำ';
    if (score >= 1) return 'อาจเหมาะ';
    return 'ทั่วไป';
  }

  Color scoreColor(int score) {
    if (score >= 5) return Colors.green;
    if (score >= 3) return Colors.orange;
    if (score >= 1) return Colors.blueGrey;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('เมนูแนะนำสำหรับคุณ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (userDisease.isEmpty && userGoal.isEmpty && userPreference.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.info, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'กรุณากรอกข้อมูลในโปรไฟล์ก่อน',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('menus')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    final scoredMenus = docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final score = calculateScore(data);
                      return {
                        'doc': doc,
                        'data': data,
                        'score': score,
                      };
                    }).toList();

                    scoredMenus.sort((a, b) =>
                        (b['score'] as int).compareTo(a['score'] as int));

                    final filteredMenus = scoredMenus
                        .where((item) => (item['score'] as int) > 0)
                        .toList();

                    if (filteredMenus.isEmpty) {
                      return const Center(
                        child: Text('ยังไม่มีเมนูที่ตรงกับข้อมูลของคุณ'),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ข้อมูลที่ใช้แนะนำ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('โรคประจำตัว: ${userDisease.isEmpty ? "-" : userDisease}'),
                              Text('เป้าหมายสุขภาพ: ${userGoal.isEmpty ? "-" : userGoal}'),
                              Text('ความชอบอาหาร: ${userPreference.isEmpty ? "-" : userPreference}'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredMenus.length,
                            itemBuilder: (context, index) {
                              final item = filteredMenus[index];
                              final data = item['data'] as Map<String, dynamic>;
                              final score = item['score'] as int;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 10,
                                      color: Colors.black.withOpacity(0.05),
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: SizedBox(
                                        height: 160,
                                        width: double.infinity,
                                        child: (data['imageUrl'] != null &&
                                                data['imageUrl']
                                                    .toString()
                                                    .startsWith('http'))
                                            ? Image.network(
                                                data['imageUrl'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    color: Colors.grey.shade200,
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.fastfood,
                                                        size: 60,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: Colors.grey.shade200,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.fastfood,
                                                    size: 60,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: scoreColor(score)
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              scoreLabel(score),
                                              style: TextStyle(
                                                color: scoreColor(score),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            data['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            data['category'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'เหมาะกับโรค: ${data['suitableForDisease'] ?? "-"}',
                                          ),
                                          Text(
                                            'เหมาะกับเป้าหมาย: ${data['suitableForGoal'] ?? "-"}',
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'คะแนนความเหมาะสม: $score',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}