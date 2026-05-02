import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _isLoading = false;

  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  final TextEditingController _registerNameController = TextEditingController();
  final TextEditingController _registerEmailController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();
  final TextEditingController _registerConfirmPasswordController =
      TextEditingController();

  String _loginError = '';
  String _registerError = '';

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _loginError = '';
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text.trim(),
      );
      if (mounted) return;
    } catch (e) {
      if (mounted) {
        setState(() => _loginError = 'Email atau password salah');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _registerError = '';
    });

    if (_registerNameController.text.trim().isEmpty) {
      if (mounted) {
        setState(() => _registerError = 'Nama lengkap harus diisi');
        setState(() => _isLoading = false);
      }
      return;
    }
    if (!_registerEmailController.text.trim().contains('.ac.id')) {
      if (mounted) {
        setState(
          () => _registerError = 'Harus menggunakan email kampus (.ac.id)',
        );
        setState(() => _isLoading = false);
      }
      return;
    }
    if (_registerPasswordController.text.length < 8) {
      if (mounted) {
        setState(() => _registerError = 'Password minimal 8 karakter');
        setState(() => _isLoading = false);
      }
      return;
    }
    if (_registerPasswordController.text !=
        _registerConfirmPasswordController.text) {
      if (mounted) {
        setState(() => _registerError = 'Konfirmasi password tidak cocok');
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      await Supabase.instance.client.auth.signUp(
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text.trim(),
        data: {'full_name': _registerNameController.text.trim()},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran berhasil! Silakan login.')),
        );
        setState(() {
          _isLogin = true;
          _registerEmailController.clear();
          _registerPasswordController.clear();
          _registerConfirmPasswordController.clear();
          _registerNameController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _registerError = 'Gagal mendaftar: ${e.toString()}');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.book, size: 45, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'NOTESHARE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 32),

                if (_isLogin) ...[
                  const Text(
                    'Masuk ke akun Anda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _loginEmailController,
                    decoration: InputDecoration(
                      labelText: 'Email Mahasiswa',
                      hintText: 'email@mahasiswa.ac.id',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _loginPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Lupa Password button removed - akan ditambahkan di update berikutnya
                  if (_loginError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _loginError,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Login', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun?'),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = false),
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: Color(0xFF1E3A5F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'Daftar Akun Baru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _registerNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      hintText: 'Masukkan nama lengkap',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _registerEmailController,
                    decoration: InputDecoration(
                      labelText: 'Email Mahasiswa',
                      hintText: 'email@mahasiswa.ac.id',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                      helperText: 'Harus menggunakan email kampus (.ac.id)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _registerPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Minimal 8 karakter',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _registerConfirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      hintText: 'Masukkan ulang password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  if (_registerError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _registerError,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Daftar',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun?'),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = true),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Color(0xFF1E3A5F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
