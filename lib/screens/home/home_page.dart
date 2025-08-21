import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Data Lists and State ---
final List<String> _wasteObservedOptions = [
  'Plastic',
  'Paper',
  'Food',
  'Metal',
  'Glass',
  'Cardboard',
  'Hazardous',
  'Other',
];

// initialize empty list to hold the selects and multiselects
List<String> _selectedWasteObserved = [];

final List<String> _lightingOptions = [
  'Bright Daylight',
  'Night/Low Light',
  'Indoor Light',
  'Other',
];

final List<String> _binOptions = [
  'Recycling',
  'Trash',
  'Compost',
  'Other',
];

// Instruction Step Widget
class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32), // Forest Green
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF212121), // Charcoal
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // initialize file, image preview and the URL of the image for the firebase DB
  File? _imageFile;
  Uint8List? _webImageBytes;
  String? _uploadedImageUrl;
  final picker = ImagePicker();

  final TextEditingController _notesController = TextEditingController();
// store the values of the lighting and bin types
  String? _selectedLighting;
  String? _selectedBin;
  final TextEditingController _customLightingController = TextEditingController();
  final TextEditingController _customBinController = TextEditingController();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    // display the image preview
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
    // Check if image is available for both web and mobile
    final noImage = (!kIsWeb && _imageFile == null) || (kIsWeb && _webImageBytes == null);
    // Verify that an image has been selected before saving
    if (noImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a picture before saving'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

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
        'wasteObserved': _selectedWasteObserved,
      });
      // Confirm that data has been stored
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Successfully logged waste'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      // update states so that users can upload multiple photos
      setState(() {
        _uploadedImageUrl = null; // Reset to show placeholder
        _imageFile = null;
        _webImageBytes = null;
        _notesController.clear();
        _selectedLighting = null;
        _customLightingController.clear();
        _selectedBin = null;
        _customBinController.clear();
        _selectedWasteObserved = [];
      });
    // error message if the upload fails
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
      backgroundColor: const Color(0xFFE8F5E9), // Light pastel green
      appBar: AppBar(
        title: const Text(
          'UCSC Waste Logging',
          style: TextStyle(color: Color(0xFF003C71)), // UCSC Blue
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF003C71)),
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
            // App Title and Description
            const Text(
              'UCSC Waste Auditing',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003C71), 
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'A crowdsourced initiative to get a better understanding of progress towards campus waste objectives',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Color(0xFF2E7D32), 
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFE8F5E9), // Light pastel green background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E7D32), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to help:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003C71), // UCSC Blue
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _InstructionStep(
                    number: '1',
                    text: 'Take a picture of your trash, recycling, or compost',
                  ),
                  const _InstructionStep(
                    number: '2',
                    text: 'Identify the contents you can see',
                  ),
                  const _InstructionStep(
                    number: '3',
                    text: 'Note the lighting conditions and any additional notes',
                  ),
                  const _InstructionStep(
                    number: '4',
                    text: 'Press save!',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Image Display
            _webImageBytes != null
                ? Image.memory(_webImageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover)
                : _imageFile != null
                    ? Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover)
                    : _uploadedImageUrl != null
                        ? Image.network(
                            _uploadedImageUrl!, 
                            height: 200, 
                            width: double.infinity, 
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Image(
                                    image: AssetImage(
                                      'assets/images/placeholder_image.png',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/placeholder_image.png',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003C71), 
                foregroundColor: Colors.white, 
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Picture', style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 16),
            // Waste Observed Multiselect
            _WasteObservedMultiSelect(
              options: _wasteObservedOptions,
              selected: _selectedWasteObserved,
              onChanged: (selected) {
                setState(() {
                  _selectedWasteObserved = selected;
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
              style: const TextStyle(color: Color(0xFF212121)),
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                labelStyle: TextStyle(color: Color(0xFF424242)), 
                hintText: 'E.g. bin was overflowing, food waste, etc',
                hintStyle: TextStyle(color: Color(0xFF424242)), 
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32)), 
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF1B5E20), width: 2), 
                ),
                filled: true,
                fillColor: Color(0xFFE8F5E9), // Light pastel green (matches select boxes)
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003C71), // UCSC Blue (was yellow)
                foregroundColor: Colors.white, // onPrimary
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.upload),
              label: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
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
          initialValue: value,
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

// Waste Observed Multiselect Widget
class _WasteObservedMultiSelect extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _WasteObservedMultiSelect({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

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
