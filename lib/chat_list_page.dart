import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_page.dart'; 

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.email == null) {
      return const Scaffold(body: Center(child: Text('กรุณาเข้าสู่ระบบ')));
    }

    final myEmail = currentUser.email!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('กล่องข้อความ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🌟 แก้ไขตรงนี้: ลบ orderBy ออก เพื่อไม่ให้ติดกฎ Index ของ Firebase
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: myEmail)
            .snapshots(),
        builder: (context, snapshot) {
          // เพิ่มเช็ค Error ให้แสดงผล (ถ้ามี) จะได้รู้ว่าติดปัญหาอะไร
          if (snapshot.hasError) return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('ยังไม่มีข้อความสนทนา', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }

          // 🌟 นำข้อมูลมาจัดเรียงเวลา (ใหม่สุดอยู่บน) ภายในแอปแทน
          final chats = snapshot.data!.docs.toList();
          chats.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['lastUpdated'] as Timestamp?;
            final bTime = bData['lastUpdated'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              final chatId = chats[index].id;
              
              // หาว่าคนที่คุยด้วยคือใคร
              final List<dynamic> participants = chat['participants'] ?? [];
              final String otherUserEmail = participants.firstWhere((email) => email != myEmail, orElse: () => 'Unknown');
              final String otherUserName = otherUserEmail.split('@')[0];
              
              // ข้อความล่าสุด
              final String lastMsg = (chat['lastMessage'] == null || chat['lastMessage'] == '') 
                  ? 'เริ่มการสนทนา...' 
                  : chat['lastMessage'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    radius: 25,
                    child: Text(otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U', style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                  title: Text(otherUserName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // กดเพื่อเปิดห้องแชท
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomPage(
                          chatId: chatId,
                          receiverEmail: otherUserEmail, 
                        ),
                      ),
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