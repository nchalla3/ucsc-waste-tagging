import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Waste Seen multiselect
final List<String> _wasteSeenOptions = [
  'Plastic',
  'Paper',
  'Food',
  'Metal',
  'Glass',
  'Cardboard',
  'Hazardous',
  'Other',
];
List<String> _selectedWasteSeen = [];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _imageFile;
  Uint8List? _webImageBytes;
  String? _uploadedImageUrl;
  final picker = ImagePicker();

  final TextEditingController _notesController = TextEditingController();

  String? _selectedLighting;
  final List<String> _lightingOptions = [
    'Bright Daylight',
    'Night/Low Light',
    'Indoor Light',
    'Other',
  ];

  String? _selectedBin;
  final List<String> _binOptions = [
    'Recycling',
    'Trash',
    'Compost',
    'Other',
  ];

  final TextEditingController _customLightingController = TextEditingController();
  final TextEditingController _customBinController = TextEditingController();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
          _webImageBytes = null;
        });
      }
    }
  }

  Future<void> _saveData() async {
    if (!kIsWeb && _imageFile == null) return;
    if (kIsWeb && _webImageBytes == null) return;

    try {
      // Upload to Firebase Storage
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child('uploads/$fileName.jpg');
      if (kIsWeb) {
        await storageRef.putData(_webImageBytes!);
      } else {
        await storageRef.putFile(_imageFile!);
      }
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
        'binType': _selectedBin == 'Other' && _customBinController.text.isNotEmpty
            ? _customBinController.text
            : _selectedBin,
        'wasteSeen': _selectedWasteSeen,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Successfully logged waste'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        _uploadedImageUrl = imageUrl;
        _imageFile = null;
        _webImageBytes = null;
        _notesController.clear();
        _selectedLighting = null;
        _customLightingController.clear();
        _selectedBin = null;
        _customBinController.clear();
        _selectedWasteSeen = [];
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
            _webImageBytes != null
                ? Image.memory(_webImageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover)
                : _imageFile != null
                    ? Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover)
                    : _uploadedImageUrl != null
                        ? Image.network(_uploadedImageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover)
                        : Image.asset(
                            'assets/images/placeholder_image.png',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Picture'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 16),
            // Waste Seen Multiselect
            _WasteSeenMultiSelect(
              options: _wasteSeenOptions,
              selected: _selectedWasteSeen,
              onChanged: (selected) {
                setState(() {
                  _selectedWasteSeen = selected;
                });
              },
            ),
            const SizedBox(height: 16),
            // Lighting Conditions Dropdown
            _DropdownWithOther(
              value: _selectedLighting,
              options: _lightingOptions,
              label: 'Lighting Conditions',
              customController: _customLightingController,
              onChanged: (value) {
                setState(() {
                  _selectedLighting = value;
                  if (value != 'Other') {
                    _customLightingController.clear();
                  }
                });
              },
              customLabel: 'Please specify lighting',
            ),
            const SizedBox(height: 16),
            // Bin Type Dropdown
            _DropdownWithOther(
              value: _selectedBin,
              options: _binOptions,
              label: 'Bin Type',
              customController: _customBinController,
              onChanged: (value) {
                setState(() {
                  _selectedBin = value;
                  if (value != 'Other') {
                    _customBinController.clear();
                  }
                });
              },
              customLabel: 'Please specify bin type',
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'E.g. bin was overflowing, food waste, etc',
                border: OutlineInputBorder(),
              ),
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

class _DropdownWithOther extends StatelessWidget {
  final String? value;
  final List<String> options;
  final String label;
  final TextEditingController customController;
  final void Function(String?) onChanged;
  final String customLabel;

  const _DropdownWithOther({
    required this.value,
    required this.options,
    required this.label,
    required this.customController,
    required this.onChanged,
    required this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: options
              .map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
        if (value == 'Other') ...[
          const SizedBox(height: 8),
          TextField(
            controller: customController,
            decoration: InputDecoration(
              labelText: customLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}

// Waste Seen Multiselect Widget
class _WasteSeenMultiSelect extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _WasteSeenMultiSelect({
    required this.options,
    required this.selected,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Waste Seen',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selectedValue) {
                final newSelected = List<String>.from(selected);
                if (selectedValue) {
                  if (!newSelected.contains(option)) newSelected.add(option);
                } else {
                  newSelected.remove(option);
                }
                onChanged(newSelected);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
