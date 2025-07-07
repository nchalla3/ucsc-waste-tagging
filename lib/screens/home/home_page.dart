import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _imageFile;
  final picker = ImagePicker();

  final TextEditingController _lightingController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveData() async {
    if (_imageFile == null) return;

    // Upload to Firebase Storage
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
    await storageRef.putFile(_imageFile!);
    final imageUrl = await storageRef.getDownloadURL();

    // Save metadata to Firestore
    await FirebaseFirestore.instance.collection('waste_reports').add({
      'imageUrl': imageUrl,
      'lighting': _lightingController.text,
      'notes': _notesController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser?.uid,
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Upload successful!'),
    ));

    setState(() {
      _imageFile = null;
      _lightingController.clear();
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UCSC Waste Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _imageFile != null
                ? Image.file(_imageFile!)
                : const Placeholder(fallbackHeight: 200),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Picture'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lightingController,
              decoration: const InputDecoration(labelText: 'Lighting Conditions'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Additional Notes'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Save to Firebase'),
              onPressed: _saveData,
            ),
          ],
        ),
      ),
    );
  }
}
