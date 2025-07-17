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

  final TextEditingController _notesController = TextEditingController();

  String? _selectedLighting;
  final List<String> _lightingOptions = [
    'Bright Daylight',
    'Night/Low Light',
    'Indoor Light',
    'Other',
  ];
  final TextEditingController _customLightingController = TextEditingController();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveData() async {
    if (_imageFile == null) return;

    try {
      // Upload to Firebase Storage
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
      await storageRef.putFile(_imageFile!);
      final imageUrl = await storageRef.getDownloadURL();

      // Save metadata to Firestore
      await FirebaseFirestore.instance.collection('waste_reports').add({
        'imageUrl': imageUrl,
        'lighting': _selectedLighting == 'Other' && _customLightingController.text.isNotEmpty
            ? _customLightingController.text
            : _selectedLighting,
        'notes': _notesController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Successfully logged waste'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        _imageFile = null;
        _notesController.clear();
        _selectedLighting = null;
        _customLightingController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save image'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UCSC Waste Logging'),
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
                : Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.grey,
                        size: 48,
                      ),
                    ),
                  ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Picture'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 16),
            // Lighting Conditions Dropdown
            DropdownButtonFormField<String>(
              value: _selectedLighting,
              decoration: const InputDecoration(
                labelText: 'Lighting Conditions',
                border: OutlineInputBorder(),
              ),
              items: _lightingOptions
                  .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLighting = value;
                  if (value != 'Other') {
                    _customLightingController.clear();
                  }
                });
              },
            ),
            if (_selectedLighting == 'Other')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextField(
                  controller: _customLightingController,
                  decoration: const InputDecoration(
                    labelText: 'Please specify lighting',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Additional Notes'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Save'),
              onPressed: _saveData,
            ),
          ],
        ),
      ),
    );
  }
}
