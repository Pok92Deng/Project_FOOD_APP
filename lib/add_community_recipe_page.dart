import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddCommunityRecipePage extends StatefulWidget {
  const AddCommunityRecipePage({super.key});

  @override
  State<AddCommunityRecipePage> createState() =>
      _AddCommunityRecipePageState();
}

class _AddCommunityRecipePageState
    extends State<AddCommunityRecipePage> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final ingredientsController = TextEditingController();
  final stepsController = TextEditingController();

  bool isLoading = false;

  Future<void> addPost() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance
          .collection('community_recipes')
          .add({
        'userId': user.uid,
        'userEmail': user.email,
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'ingredients': ingredientsController.text.trim(),
        'steps': stepsController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    ingredientsController.dispose();
    stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('โพสต์สูตร')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'ชื่อสูตร')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'รายละเอียด')),
            TextField(controller: ingredientsController, decoration: const InputDecoration(labelText: 'วัตถุดิบ')),
            TextField(controller: stepsController, decoration: const InputDecoration(labelText: 'วิธีทำ')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : addPost,
              child: const Text('โพสต์'),
            ),
          ],
        ),
      ),
    );
  }
}