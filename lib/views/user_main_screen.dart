import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';
import '../services/api_service.dart';
import '../services/api_path.dart';
import 'add_report_screen.dart';
import 'edit_report_screen.dart';
import 'login_screen.dart';
import 'report_detail_screen.dart';
import 'profile_screen.dart';

class UserMainScreen extends StatefulWidget {
  final UserModel user;
  const UserMainScreen({super.key, required this.user});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
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
                Navigator.of(context).pop(); // Close dialog
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

  Future<void> _deleteReport(ReportModel report) async {
    try {
      final response = await ApiService.postRequest('delete_report.php', {
        'report_id': report.reportId.toString(),
        'user_id': widget.user.id.toString(),
        'user_role': widget.user.role,
      });

      if (!mounted) return;

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchReports(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Delete failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.postRequest('get_posts.php', {
        'user_id': widget.user.id.toString(),
        'role': widget.user.role,
      });

      // DEBUG
      print("DEBUG: Raw API Response: $response");

      if (mounted && response['status'] == 'success') {
        final List<dynamic> reports = response['reports'] ?? [];
        setState(() {
          _reports = reports.map((json) => ReportModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        // DEBUG
        print(
          "DEBUG: API Error/Empty: ${response['message'] ?? 'Unknown error'}",
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("DEBUG: Catch Exception: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ReportModel> get _filteredApproved {
    return _reports.where((report) {
      final matchesSearch = report.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          (_selectedCategory == 'All' || report.category == _selectedCategory);
      final isApproved = report.status.toLowerCase() == 'approved';
      final isNotOwner = report.userId.toString() != widget.user.id.toString();

      // DEBUG
      print(
        "Filter Check: ${report.title} | Status: ${report.status} | Matches: ${isApproved && matchesSearch && matchesCategory}",
      );

      return isApproved && isNotOwner && matchesSearch && matchesCategory;
    }).toList();
  }

  List<ReportModel> get _filteredMyPosts {
    return _reports.where((report) {
      final matchesSearch = report.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          (_selectedCategory == 'All' || report.category == _selectedCategory);
      final isOwner = report.userId.toString() == widget.user.id.toString();
      return isOwner && matchesSearch && matchesCategory;
    }).toList();
  }

  bool _canEditOrDelete(ReportModel report) {
    final currentUserRole = widget.user.role.toLowerCase();
    final isOwner = report.userId.toString() == widget.user.id.toString();
    final isAdminOrLecturer =
        currentUserRole == 'admin' || currentUserRole == 'lecturer';
    return isOwner || isAdminOrLecturer;
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: report.image.isNotEmpty
              ? NetworkImage(
                  "${ApiPath.imageUrl}/uploads/reports/${report.image}",
                )
              : const AssetImage("assets/placeholder.png") as ImageProvider,
        ),
        title: Text(report.title),
        subtitle: Text(
          "Category: ${report.category} | Status: ${report.status}",
        ),
        trailing: _canEditOrDelete(report)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditReportScreen(report: report),
                        ),
                      );
                      if (result == true) _fetchReports();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Report updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(report),
                  ),
                ],
              )
            : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(report: report),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lost & Found'),
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
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'All Approved'),
              Tab(text: 'My Posts'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Title',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _filteredApproved.isEmpty
                            ? const Center(child: Text("No posts found"))
                            : ListView.builder(
                                itemCount: _filteredApproved.length,
                                itemBuilder: (context, index) =>
                                    _buildReportCard(_filteredApproved[index]),
                              ),
                        _filteredMyPosts.isEmpty
                            ? const Center(child: Text("No posts found"))
                            : ListView.builder(
                                itemCount: _filteredMyPosts.length,
                                itemBuilder: (context, index) =>
                                    _buildReportCard(_filteredMyPosts[index]),
                              ),
                      ],
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddReportScreen(user: widget.user),
              ),
            );
            if (result == true) _fetchReports();
          },
        ),
      ),
    );
  }
}
