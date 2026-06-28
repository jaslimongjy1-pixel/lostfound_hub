import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api_path.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddReportScreen extends StatefulWidget {
  final UserModel user;
  const AddReportScreen({super.key, required this.user});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController locController = TextEditingController();

  // To store the selected image
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  String? selectedType;
  String? selectedCategory;
  final List<String> types = ['Lost', 'Found'];
  final List<String> categories = [
    'Electronics',
    'Personal Items',
    'Documents',
    'Others',
  ];

  // Method to pick image
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Take a Photo"),
            onTap: () async {
              Navigator.pop(context);
              final XFile? photo = await _picker.pickImage(
                source: ImageSource.camera,
              );
              if (photo != null) setState(() => _imageFile = File(photo.path));
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Choose from Gallery"),
            onTap: () async {
              Navigator.pop(context);
              final XFile? pickedFile = await _picker.pickImage(
                source: ImageSource.gallery,
              );
              if (pickedFile != null)
                setState(() => _imageFile = File(pickedFile.path));
            },
          ),
        ],
      ),
    );
  }

  // Method to upload
  Future<void> _submitReport() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.get('user_id');
    final String? userIdString = savedId?.toString();

    print("DEBUG: Fetched user_id from memory: $userIdString");

    if (userIdString == null || userIdString == "null") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: User session lost. Please re-login."),
        ),
      );
      return;
    }

    // Validation check
    if (_imageFile == null ||
        titleController.text.isEmpty ||
        selectedType == null ||
        selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select an image"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiPath.endpoint("add_report.php")),
      );

      request.fields['user_id'] = userIdString;
      request.fields['report_title'] = titleController.text;
      request.fields['report_type'] = selectedType!;
      request.fields['report_category'] = selectedCategory!;
      request.fields['report_location'] = locController.text;
      request.fields['report_description'] = descController.text;

      //Send the image
      request.files.add(
        await http.MultipartFile.fromPath('image', _imageFile!.path),
      );

      var response = await request.send();
      var responseData = await response.stream
          .bytesToString(); // Get the server response

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        throw Exception('Server returned error: $responseData');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Report")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[200],
                child: _imageFile == null
                    ? const Center(child: Icon(Icons.add_a_photo, size: 50))
                    : Image.file(_imageFile!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: locController,
              decoration: const InputDecoration(labelText: "Location"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Report Type"),
              initialValue: selectedType,
              items: types
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedType = value),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Category"),
              initialValue: selectedCategory,
              items: categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCategory = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitReport,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Submit Report"),
            ),
          ],
        ),
      ),
    );
  }
}
