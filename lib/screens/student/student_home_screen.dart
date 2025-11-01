import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/student_api_service.dart';
import '../../models/class_model.dart';
import '../login_screen.dart';
import 'student_class_detail_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final StudentApiService _studentApiService = StudentApiService();
  List<ClassModel> _classes = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _loading = true);
    try {
      final classes = await _studentApiService.getMyClasses();
      if (mounted) setState(() => _classes = classes);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showJoinClassDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Class'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(labelText: 'Class Code'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.trim().isEmpty) return;
              try {
                await _studentApiService.joinClass(codeController.text.trim());
                Navigator.pop(context);
                _loadClasses();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined class!')));
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    ).then((_) => codeController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          IconButton(onPressed: _loadClasses, icon: const Icon(Icons.refresh)),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? const Center(child: Text('No classes. Tap + to join one.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final classData = _classes[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.class_),
                        title: Text(classData.name),
                        subtitle: Text('Code: ${classData.code}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => StudentClassDetailScreen(classModel: classData)),
                        ).then((_) => _loadClasses()),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showJoinClassDialog,
        icon: const Icon(Icons.add),
        label: const Text('Join Class'),
      ),
    );
  }
}
