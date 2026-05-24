import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String targetEmail; // อีเมลของคนที่เราต้องการคุยด้วย

  const ChatPage({super.key, required this.targetEmail});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ฟังก์ชันสร้าง ID ห้องแชทแบบไม่ซ้ำ (เอาอีเมล 2 คนมาเรียงตามตัวอักษร)
  String getChatRoomId(String user1, String user2) {
    if (user1.toLowerCase().compareTo(user2.toLowerCase()) > 0) {
      return '${user1}_$user2';
    } else {
      return '${user2}_$user1';
    }
  }

  void sendMessage() async {
    final String message = _messageController.text.trim();
    if (message.isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final String currentEmail = currentUser.email ?? '';
    final String chatRoomId = getChatRoomId(currentEmail, widget.targetEmail);

    final Map<String, dynamic> messageData = {
      'senderEmail': currentEmail,
      'receiverEmail': widget.targetEmail,
      'message': message,
      'createdAt': Timestamp.now(),
    };

    _messageController.clear();

    // บันทึกข้อความลง Firestore
    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);
        
    // อัปเดตข้อมูลห้องแชทล่าสุด
    await _firestore.collection('chats').doc(chatRoomId).set({
      'users': [currentEmail, widget.targetEmail],
      'lastMessage': message,
      'lastUpdated': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final currentEmail = currentUser?.email ?? '';
    final chatRoomId = getChatRoomId(currentEmail, widget.targetEmail);
    final targetName = widget.targetEmail.split('@')[0]; // ตัดเอาแค่ชื่อหน้า @

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              radius: 16,
              child: Text(targetName[0].toUpperCase(), style: TextStyle(color: Colors.green.shade900, fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Text(targetName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // 1. ส่วนแสดงพื้นที่ข้อความแชท
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อความ'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data?.docs ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.waving_hand, size: 60, color: Colors.orange.shade300),
                        const SizedBox(height: 16),
                        Text('เริ่มต้นทักทาย $targetName เลย!', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderEmail'] == currentEmail;

                    return Container(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          data['message'],
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // 2. ส่วนพิมพ์ข้อความ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ข้อความ...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}