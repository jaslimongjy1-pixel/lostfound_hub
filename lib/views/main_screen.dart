import 'package:flutter/material.dart';
import '../services/api_path.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'report_detail_screen.dart';
import 'edit_report_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final UserModel user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<ReportModel> _reports = [];
  bool _isLoading = true;

  // Search & Filter State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Electronics',
    'Personal Items',
    'Documents',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtering Logic
  List<ReportModel> get _filteredReports {
    return _reports.where((report) {
      final matchesSearch = report.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          (_selectedCategory == 'All' || report.category == _selectedCategory);
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getRequest('get_pending.php');
      if (!mounted) return;
      if (response['status'] == 'success') {
        setState(() {
          _reports = (response['reports'] as List)
              .map((item) => ReportModel.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteReport(ReportModel report) async {
    final response = await ApiService.postRequest('delete_report.php', {
      'report_id': report.reportId.toString(),
      'user_id': widget.user.id.toString(),
      'user_role': widget.user.role,
    });
    if (response['status'] == 'success') {
      _fetchReports();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Delete failed')),
        );
      }
    }
  }

  Future<void> _updateStatus(int reportId, String newStatus) async {
    final response = await ApiService.postRequest('update_status.php', {
      'report_id': reportId.toString(),
      'new_status': newStatus,
    });
    if (!mounted) return;
    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report has been $newStatus successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchReports();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Update failed')),
      );
    }
  }

  void _showStatusConfirmation(int reportId, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm $status"),
        content: Text("Are you sure you want to change the status to $status?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(reportId, status);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ReportModel report) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Report"),
          content: const Text(
            "Are you sure you want to delete this report? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteReport(report);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPrivileged =
        widget.user.role.toLowerCase() == 'admin' ||
        widget.user.role.toLowerCase() == 'lecturer';

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${widget.user.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(user: widget.user),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Title',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 5),
                    ),
                    items: _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                  ),
                ),
              ],
            ),
          ),
          // List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReports.isEmpty
                ? const Center(child: Text("No posts found"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = _filteredReports[index];
                      final bool isOwner =
                          report.userId.toString() == widget.user.id.toString();
                      final bool isPending =
                          report.status.toLowerCase() == 'pending';
                      final String imageUrl = report.image.isNotEmpty
                          ? "${ApiPath.imageUrl}/uploads/reports/${report.image}"
                          : "";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReportDetailScreen(report: report),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (imageUrl.isNotEmpty)
                                Image.network(
                                  imageUrl,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => const SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      "Status: ${report.status} | Type: ${report.type}",
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (isPrivileged || isOwner) ...[
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () async {
                                              final result =
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditReportScreen(
                                                            report: report,
                                                          ),
                                                    ),
                                                  );
                                              if (result == true) {
                                                _fetchReports();
                                              }
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Report updated successfully!',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _showDeleteConfirmation(report),
                                          ),
                                        ],
                                        if (isPrivileged && isPending) ...[
                                          TextButton(
                                            onPressed: () =>
                                                _showStatusConfirmation(
                                                  report.reportId,
                                                  'Rejected',
                                                ),
                                            child: const Text(
                                              'REJECT',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                _showStatusConfirmation(
                                                  report.reportId,
                                                  'Approved',
                                                ),
                                            child: const Text('APPROVE'),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
