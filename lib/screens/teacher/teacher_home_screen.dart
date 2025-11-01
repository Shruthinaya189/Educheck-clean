import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

import '../../config/api_config.dart';
import '../../models/class_model.dart';
import '../../services/auth_service.dart';
import '../../services/class_api_service.dart';
import '../login_screen.dart';
import 'class_detail_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final AuthService _authService = AuthService();
  final ClassApiService _classApiService = ClassApiService();
  final ImagePicker _picker = ImagePicker();

  List<ClassModel> _classes = [];
  String _selectedCategory = 'All';
  bool _showArchived = false;
  bool _isDarkMode = false;
  bool _loading = false;
  String? _error;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = await _classApiService.getTeacherClasses(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _lastRefreshTime = DateTime.now();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRefresh() async {
    if (_lastRefreshTime != null && DateTime.now().difference(_lastRefreshTime!) < const Duration(seconds: 2)) return;
    await _loadClasses(forceRefresh: true);
  }

  List<ClassModel> get _filteredClasses {
    var filtered = _classes.where((c) => c.isArchived == _showArchived);
    if (_selectedCategory != 'All') {
      filtered = filtered.where((c) => c.category == _selectedCategory);
    }
    return filtered.toList();
  }

  Future<void> _uploadPapers() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return;

      setState(() => _loading = true);

      final uri = Uri.parse(ApiConfig.baseUrl + '/api/uploads/images-to-pdf');
      final req = http.MultipartRequest('POST', uri);

      for (final img in images) {
        req.files.add(await http.MultipartFile.fromPath('files', img.path, filename: img.name, contentType: MediaType('image', _extToMime(img.path))));
      }

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final url = data['url'] as String;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload complete. PDF URL: $url')));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed (${resp.statusCode})'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _extToMime(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'png';
    if (p.endsWith('.webp')) return 'webp';
    return 'jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = _isDarkMode ? ThemeData.dark() : ThemeData.light();
    return Theme(
      data: theme.copyWith(
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: _isDarkMode ? Colors.black38 : Colors.blue.shade600,
          foregroundColor: Colors.white,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.blue)),
          ),
          title: const Text('My Classes'),
          actions: [
            IconButton(
              icon: Icon(_showArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
              tooltip: _showArchived ? 'Show Active' : 'Show Archived',
              onPressed: () => setState(() => _showArchived = !_showArchived),
            ),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _handleRefresh,
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'upload', child: ListTile(leading: Icon(Icons.upload_file), title: Text('Upload Papers'), contentPadding: EdgeInsets.zero)),
                PopupMenuItem(value: 'toggle_theme', child: ListTile(leading: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode), title: Text(_isDarkMode ? 'Light Mode' : 'Dark Mode'), contentPadding: EdgeInsets.zero)),
                const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Logout', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero)),
              ],
              onSelected: (value) async {
                if (value == 'upload') {
                  await _uploadPapers();
                } else if (value == 'toggle_theme') {
                  setState(() => _isDarkMode = !_isDarkMode);
                } else if (value == 'logout') {
                  await FirebaseAuth.instance.signOut();
                  await _authService.logout();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false);
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['All', '1st Year', '2nd Year', '3rd Year', '4th Year']
                    .map((category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(category == 'All' ? Icons.grid_view : Icons.class_, size: 18, color: _selectedCategory == category ? Colors.white : theme.textTheme.bodyMedium?.color),
                            label: Text(category),
                            selected: _selectedCategory == category,
                            selectedColor: Colors.blue,
                            backgroundColor: theme.brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
                            labelStyle: TextStyle(color: _selectedCategory == category ? Colors.white : theme.textTheme.bodyMedium?.color),
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedCategory = category);
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
            Expanded(
              child: _loading && _classes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _classes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(onPressed: () => _loadClasses(forceRefresh: true), icon: const Icon(Icons.refresh), label: const Text('Retry')),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadClasses(forceRefresh: true),
                          child: _filteredClasses.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(_showArchived ? Icons.archive_outlined : Icons.class_outlined, size: 100, color: Colors.grey.shade300),
                                          const SizedBox(height: 24),
                                          Text(_showArchived ? 'No archived classes' : 'No classes yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                                          if (!_showArchived) ...[
                                            const SizedBox(height: 12),
                                            Text('Tap + to create your first class', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredClasses.length,
                                  itemBuilder: (context, index) {
                                    final classData = _filteredClasses[index];
                                    final colors = [
                                      [Colors.blue.shade400, Colors.blue.shade700],
                                      [Colors.purple.shade400, Colors.purple.shade700],
                                      [Colors.green.shade400, Colors.green.shade700],
                                      [Colors.orange.shade400, Colors.orange.shade700],
                                      [Colors.pink.shade400, Colors.pink.shade700],
                                    ];
                                    final colorPair = colors[classData.name.hashCode.abs() % colors.length];

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: colorPair, begin: Alignment.topLeft, end: Alignment.bottomRight),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [BoxShadow(color: colorPair[1].withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ClassDetailScreen(classModel: classData))),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.class_, color: Colors.white, size: 24)),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(classData.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                                          const SizedBox(height: 4),
                                                          Text('Code: ${classData.code}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                                        ],
                                                      ),
                                                    ),
                                                    PopupMenuButton(
                                                      icon: const Icon(Icons.more_vert, color: Colors.white),
                                                      itemBuilder: (context) => [
                                                        if (!_showArchived) const PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share), title: Text('Share'), contentPadding: EdgeInsets.zero)),
                                                        if (!_showArchived) const PopupMenuItem(value: 'qr', child: ListTile(leading: Icon(Icons.qr_code), title: Text('QR Code'), contentPadding: EdgeInsets.zero)),
                                                        PopupMenuItem(value: _showArchived ? 'unarchive' : 'archive', child: ListTile(leading: Icon(_showArchived ? Icons.unarchive : Icons.archive), title: Text(_showArchived ? 'Unarchive' : 'Archive'), contentPadding: EdgeInsets.zero)),
                                                        const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero)),
                                                      ],
                                                      onSelected: (value) => _handleMenuAction(value.toString(), classData),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    _buildTag(Icons.school, classData.category),
                                                    const SizedBox(width: 12),
                                                    _buildTag(Icons.people, '${classData.enrolledStudents.length}'),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  },
                                ),
                        ),
            ),
          ],
        ),
        floatingActionButton: _showArchived ? null : FloatingActionButton.extended(onPressed: _showCreateClassDialog, icon: const Icon(Icons.add), label: const Text('Create Class')),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(icon, color: Colors.white, size: 14), const SizedBox(width: 4), Text(text, style: const TextStyle(color: Colors.white, fontSize: 12))]),
    );
  }

  void _handleMenuAction(String action, ClassModel classData) {
    switch (action) {
      case 'share':
        Clipboard.setData(ClipboardData(text: 'Join my class "${classData.name}"\nClass Code: ${classData.code}\n\nDownload EduCheck to join!'));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Class details copied!')));
        break;
      case 'qr':
        _showQrDialog(classData);
        break;
      case 'archive':
      case 'unarchive':
        _classApiService.updateClass(classData.id, {'is_archived': action == 'archive'}).then((_) => _loadClasses());
        break;
      case 'delete':
        _showDeleteConfirmationDialog(classData);
        break;
    }
  }

  void _showDeleteConfirmationDialog(ClassModel classData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning_amber, color: Colors.orange), SizedBox(width: 12), Text('Delete Class')]),
        content: Text('Are you sure you want to delete "${classData.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await _classApiService.deleteClass(classData.id);
                if (!mounted) return;
                Navigator.pop(context);
                _loadClasses();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${classData.name} deleted')));
              } on ApiException catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateClassDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController(text: 'C${DateTime.now().millisecondsSinceEpoch % 1000000}');
    String selectedCategory = '1st Year';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.add_box, color: Colors.blue), SizedBox(width: 12), Text('Create New Class')]),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Class Name', hintText: 'e.g., Mathematics', prefixIcon: Icon(Icons.class_), border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: 'Class Code',
                    prefixIcon: const Icon(Icons.code),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(icon: const Icon(Icons.refresh), onPressed: () => setDialogState(() => codeController.text = 'C${DateTime.now().millisecondsSinceEpoch % 1000000}')),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Year/Category', prefixIcon: Icon(Icons.school), border: OutlineInputBorder()),
                  items: ['1st Year', '2nd Year', '3rd Year', '4th Year'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => selectedCategory = v!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class name is required.')));
                return;
              }
              try {
                await _classApiService.createClass({"name": nameController.text.trim(), "code": codeController.text, "category": selectedCategory});
                if (!mounted) return;
                Navigator.pop(context);
                _loadClasses();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nameController.text} created!')));
              } on ApiException catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            icon: const Icon(Icons.check),
            label: const Text('Create'),
          ),
        ],
      ),
    ).then((_) {
      nameController.dispose();
      codeController.dispose();
    });
  }

  void _showQrDialog(ClassModel classData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [const Icon(Icons.qr_code_2, color: Colors.blue), const SizedBox(width: 12), Text(classData.name)]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: classData.code, size: 200, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black), dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black)),
            ),
            const SizedBox(height: 16),
            Text('Code: ${classData.code}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Scan to join class', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: classData.code)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!'))); }, icon: const Icon(Icons.copy), label: const Text('Copy Code')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
