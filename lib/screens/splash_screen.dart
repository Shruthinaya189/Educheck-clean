import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'teacher/teacher_home_screen.dart';
import 'student/student_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _auth = AuthService();
  static const _storage = FlutterSecureStorage();
  static const _kRemember = 'remember_me';
  static const _kEmail = 'saved_email';
  static const _kPassword = 'saved_password';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Small delay for UX
    await Future.delayed(const Duration(milliseconds: 200));

    // If token exists, route by role
    if (await _auth.isLoggedIn()) {
      final role = await _auth.currentUserRole();
      if (!mounted) return;
      if (role == 'teacher') return _go(const TeacherHomeScreen());
      if (role == 'student') return _go(const StudentHomeScreen());
      await _auth.logout();
    } else {
      // Try auto-login via saved credentials
      final remember = await _storage.read(key: _kRemember);
      if (remember == 'true') {
        final email = await _storage.read(key: _kEmail);
        final pwd = await _storage.read(key: _kPassword);
        if (email != null && pwd != null) {
          try {
            await _auth.login(email, pwd);
            final role = await _auth.currentUserRole();
            if (!mounted) return;
            if (role == 'teacher') return _go(const TeacherHomeScreen());
            if (role == 'student') return _go(const StudentHomeScreen());
          } catch (_) {
            // fall through
          }
        }
      }
    }
    if (!mounted) return;
    _go(const LoginScreen());
  }

  void _go(Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
