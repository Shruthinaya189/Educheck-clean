import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ADD THIS
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'teacher/teacher_home_screen.dart';
import 'student/student_home_screen.dart';
import '../config/api_config.dart'; // optional if you want to read config
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // Use Android OAuth client from google-services.json
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    // No serverClientId needed for Android (uses google-services.json)
  );

  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Remember me storage
  static const _storage = FlutterSecureStorage();
  static const _kRemember = 'remember_me';
  static const _kEmail = 'saved_email';
  static const _kPassword = 'saved_password';
  static const _kRole = 'user_role'; // NEW: persist role

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State
  bool _loading = false;
  bool _isLogin = true;
  bool _isTeacher = true;

  // NEW: UI states
  bool _obscurePwd = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _isLogin = _tabController.index == 0));
    _loadSavedCreds();
  }

  Future<void> _loadSavedCreds() async {
    final remember = await _storage.read(key: _kRemember);
    if (remember == 'true') {
      final email = await _storage.read(key: _kEmail);
      final pwd = await _storage.read(key: _kPassword);
      setState(() {
        _rememberMe = true;
        if (email != null) _emailController.text = email;
        if (pwd != null) _passwordController.text = pwd;
      });
    }
  }

  Future<void> _persistCredsOnLoginSuccess() async {
    if (_rememberMe) {
      await _storage.write(key: _kRemember, value: 'true');
      await _storage.write(key: _kEmail, value: _emailController.text.trim());
      await _storage.write(key: _kPassword, value: _passwordController.text);
    } else {
      await _storage.delete(key: _kRemember);
      await _storage.delete(key: _kEmail);
      await _storage.delete(key: _kPassword);
    }
    // Also persist role so Splash/next launches can route
    await _storage.write(key: _kRole, value: _isTeacher ? 'teacher' : 'student');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_isLogin) {
        // sign in with timeout
        final userCred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            )
            .timeout(const Duration(seconds: 15));
        await _persistCredsOnLoginSuccess();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => _isTeacher ? const TeacherHomeScreen() : const StudentHomeScreen()),
        );
      } else {
        // register with timeout
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            )
            .timeout(const Duration(seconds: 20));

        if (_nameController.text.trim().isNotEmpty) {
          await cred.user?.updateDisplayName(_nameController.text.trim());
        }

        // Save user role to Firestore (merge in case of existing)
        if (cred.user != null) {
          await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
            'displayName': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'role': _isTeacher ? 'teacher' : 'student',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        await _storage.write(key: _kRole, value: _isTeacher ? 'teacher' : 'student');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful! Please log in.')));
        _tabController.animateTo(0);
      }
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Authentication error: ${e.code}';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } on TimeoutException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network timeout. Please try again.'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      // timeout the interactive sign-in
      final account = await _googleSignIn.signIn().timeout(const Duration(seconds: 20), onTimeout: () => null);
      if (account == null) {
        // user cancelled or timeout; ensure loading cleared
        if (mounted) setState(() => _loading = false);
        if (account == null) {
          // if timeout we already cleared; inform user if desired
          return;
        }
        return;
      }

      final googleAuth = await account.authentication.timeout(const Duration(seconds: 10));
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google did not return an idToken.'), backgroundColor: Colors.orange));
          setState(() => _loading = false);
        }
        return;
      }

      try {
        final credential = GoogleAuthProvider.credential(idToken: idToken, accessToken: accessToken);
        final cred = await FirebaseAuth.instance.signInWithCredential(credential).timeout(const Duration(seconds: 15));

        if (cred.user != null) {
          await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
            'displayName': cred.user!.displayName ?? 'User',
            'email': cred.user!.email ?? '',
            'role': _isTeacher ? 'teacher' : 'student',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        await _storage.write(key: _kRole, value: _isTeacher ? 'teacher' : 'student');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => _isTeacher ? const TeacherHomeScreen() : const StudentHomeScreen()),
        );
      } on FirebaseAuthException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? e.code), backgroundColor: Colors.red));
      }
    } on TimeoutException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in timed out. Check your network.'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Header
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.school, size: 40, color: Color(0xFF1E3A8A)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Sign in to continue' : 'Create your account',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 40),

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF6B7280),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Role Selection
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isTeacher = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isTeacher ? const Color(0xFF1E3A8A) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school,
                                  color: _isTeacher ? Colors.white : const Color(0xFF6B7280),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Teacher',
                                  style: TextStyle(
                                    color: _isTeacher ? Colors.white : const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isTeacher = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isTeacher ? const Color(0xFF1E3A8A) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person,
                                  color: !_isTeacher ? Colors.white : const Color(0xFF6B7280),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Student',
                                  style: TextStyle(
                                    color: !_isTeacher ? Colors.white : const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!_isLogin) ...[
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            validator: (v) => v?.trim().isEmpty == true ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 20),
                        ],
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v?.contains('@') != true ? 'Enter valid email' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePwd,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePwd ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                          ),
                          validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null, // FIXED
                        ),
                        const SizedBox(height: 20),

                        // Remember Me & Forgot Password
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (val) => setState(() => _rememberMe = val ?? false),
                              activeColor: const Color(0xFF1E3A8A),
                            ),
                            const Text('Remember me'),
                            const Spacer(),
                            if (_isLogin)
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Color(0xFF1E3A8A)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Login/Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    _isLogin ? 'Sign In' : 'Create Account',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR', style: TextStyle(color: Color(0xFF6B7280))),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Google Sign In
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                            label: const Text(
                              'Continue with Google',
                              style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
      ),
    );
  }

  // ...existing methods (_handleAuth, _signInWithGoogle, etc.)...
}
