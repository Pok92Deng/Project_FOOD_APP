import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String receiverEmail;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.receiverEmail,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.email == null) return;

    _messageController.clear();

    // 1. เพิ่มข้อความลงใน subcollection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderEmail': currentUser.email,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. อัปเดตข้อความล่าสุดในแชทหลัก (ย้ำกันเหนียวให้ข้อมูลสมบูรณ์)
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
      'participants': [currentUser.email, widget.receiverEmail],
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final receiverName = widget.receiverEmail.split('@')[0];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(receiverName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // 🌟 ถอด orderBy ออกเพื่อแก้ปัญหาข้อความหายหรือเด้งดีเลย์
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                // 🌟 เอาข้อความมาจัดเรียงความเก่า-ใหม่ ภายในแอปแทน (ข้อความใหม่สุดอยู่บน)
                final messages = snapshot.data!.docs.toList();
                messages.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['createdAt'] as Timestamp?;
                  final bTime = bData['createdAt'] as Timestamp?;
                  
                  if (aTime == null) return -1; // ถ้าเป็น null แปลว่าเพิ่งกดส่ง ให้อยู่ล่าสุดทันที
                  if (bTime == null) return 1;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  reverse: true, // ให้แชทเลื่อนจากล่างขึ้นบน
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final bool isMe = msg['senderEmail'] == currentUser?.email;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // แถบพิมพ์ข้อความ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
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
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}