import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_path.dart';
import '../models/report_model.dart';

class EditReportScreen extends StatefulWidget {
  final ReportModel report;

  const EditReportScreen({super.key, required this.report});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.report.title;
    _descController.text = widget.report.description;
    _locController.text = widget.report.location;
    selectedType = widget.report.type.isNotEmpty ? widget.report.type : null;
    selectedCategory = widget.report.category.isNotEmpty
        ? widget.report.category
        : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a Photo'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? photo = await _picker.pickImage(
                source: ImageSource.camera,
              );
              if (photo != null) {
                setState(() => _imageFile = File(photo.path));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? pickedFile = await _picker.pickImage(
                source: ImageSource.gallery,
              );
              if (pickedFile != null) {
                setState(() => _imageFile = File(pickedFile.path));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_titleController.text.trim().isEmpty ||
        _locController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        selectedType == null ||
        selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id') ?? '';
      final currentUserRole = prefs.getString('user_role') ?? '';

      print(
        'DEBUG [EDIT SUBMIT]: userId=$currentUserId, role=$currentUserRole',
      );

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiPath.endpoint('update_report.php')),
      );

      request.fields['report_id'] = widget.report.reportId.toString();
      request.fields['user_id'] = currentUserId;
      request.fields['user_role'] = currentUserRole;
      request.fields['report_title'] = _titleController.text.trim();
      request.fields['report_type'] = selectedType!;
      request.fields['report_category'] = selectedCategory!;
      request.fields['report_location'] = _locController.text.trim();
      request.fields['report_description'] = _descController.text.trim();
      request.fields['report_status'] = widget.report.status;

      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _imageFile!.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        throw Exception(responseBody);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.report.image.isNotEmpty
        ? '${ApiPath.imageUrl}/uploads/reports/${widget.report.image}'
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Report')),
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
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : (imageUrl != null
                          ? Image.network(imageUrl, fit: BoxFit.cover)
                          : const Center(
                              child: Icon(Icons.add_a_photo, size: 50),
                            )),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _locController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Report Type'),
              initialValue: selectedType,
              items: types
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedType = value),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
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
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Update Report'),
            ),
          ],
        ),
      ),
    );
  }
}
