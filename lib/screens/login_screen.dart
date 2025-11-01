import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'teacher/teacher_home_screen.dart';
import 'student/student_home_screen.dart';
import '../config/api_config.dart'; // optional if you want to read config

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // Use Web client ID from config
  static const String kGoogleWebClientId = ApiConfig.googleWebClientId;

  // Initialize GoogleSignIn with serverClientId only if non-empty
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: ApiConfig.googleWebClientId.isNotEmpty ? ApiConfig.googleWebClientId : null,
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
        // Firebase email/password sign-in
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await _persistCredsOnLoginSuccess();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => _isTeacher ? const TeacherHomeScreen() : const StudentHomeScreen()),
        );
      } else {
        // Firebase email/password register
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (_nameController.text.trim().isNotEmpty) {
          await cred.user?.updateDisplayName(_nameController.text.trim());
        }
        // Save role for navigation
        await _storage.write(key: _kRole, value: _isTeacher ? 'teacher' : 'student');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful! Please log in.')));
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return; // user cancelled
      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Google did not return an idToken. Set a valid Web client ID.'),
          backgroundColor: Colors.orange,
        ));
        return;
      }
      setState(() => _loading = true);
      try {
        // Sign in to Firebase with Google credential
        final credential = GoogleAuthProvider.credential(idToken: idToken, accessToken: accessToken);
        await FirebaseAuth.instance.signInWithCredential(credential);
        // Persist chosen role toggle for navigation
        await _storage.write(key: _kRole, value: _isTeacher ? 'teacher' : 'student');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => _isTeacher ? const TeacherHomeScreen() : const StudentHomeScreen()),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google sign-in failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // App Logo and Title
                const Icon(Icons.school, size: 80, color: Colors.blue),
                const SizedBox(height: 16),
                const Text('EduCheck', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Welcome back!' : 'Create your account',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Tab Bar for Login/Sign Up
                TabBar(
                  controller: _tabController,
                  tabs: const [Tab(text: 'Login'), Tab(text: 'Sign Up')],
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                ),
                const SizedBox(height: 16),

                // Role Toggle
                ToggleButtons(
                  isSelected: [_isTeacher, !_isTeacher],
                  onPressed: (idx) => setState(() => _isTeacher = idx == 0),
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Teacher')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Student')),
                  ],
                ),
                const SizedBox(height: 16),

                // Form Fields
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 12),
                // Password with eye icon
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePwd ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                    ),
                  ),
                  obscureText: _obscurePwd,
                  validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (val) => setState(() => _rememberMe = val ?? false),
                    ),
                    const Text('Remember me'),
                    const Spacer(),
                    if (_isLogin)
                      TextButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Forgot password not implemented'))),
                        child: const Text('Forgot password?'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _handleAuth,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                        child: Text(_isLogin ? 'Login' : 'Sign Up'),
                      ),
                const SizedBox(height: 12),
                // Google Sign-In button (client-only)
                OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
