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

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();

  String _loginError = '';
  String _registerError = '';

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();

    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();

    super.dispose();
  }

  bool _isValidCampusEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.ac\.id$');
    return regex.hasMatch(email);
  }

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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login berhasil'),
          backgroundColor: Colors.green,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _loginError = e.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loginError = 'Terjadi kesalahan saat login';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _registerError = '';
    });

    final name = _registerNameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();
    final confirmPassword = _registerConfirmPasswordController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _registerError = 'Nama lengkap harus diisi';
        _isLoading = false;
      });
      return;
    }

    if (!_isValidCampusEmail(email)) {
      setState(() {
        _registerError =
            'Gunakan email kampus yang valid (contoh: nama@kampus.ac.id)';
        _isLoading = false;
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _registerError = 'Password minimal 8 karakter';
        _isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _registerError = 'Konfirmasi password tidak cocok';
        _isLoading = false;
      });
      return;
    }

    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil! Silakan cek email verifikasi.'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _isLogin = true;

        _registerNameController.clear();
        _registerEmailController.clear();
        _registerPasswordController.clear();
        _registerConfirmPasswordController.clear();
      });
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _registerError = e.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _registerError = 'Terjadi kesalahan saat mendaftar';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon),
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A5F),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildError(String message) {
    if (message.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
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
                    decoration: _inputDecoration(
                      label: 'Email Mahasiswa',
                      hint: 'nama@kampus.ac.id',
                      icon: Icons.email_outlined,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _loginPasswordController,
                    obscureText: true,
                    decoration: _inputDecoration(
                      label: 'Password',
                      hint: 'Masukkan password',
                      icon: Icons.lock_outline,
                    ),
                  ),

                  _buildError(_loginError),

                  const SizedBox(height: 20),

                  _buildButton(text: 'Login', onPressed: _handleLogin),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun?'),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = false;
                            _loginError = '';
                          });
                        },
                        child: const Text('Daftar'),
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
                    decoration: _inputDecoration(
                      label: 'Nama Lengkap',
                      hint: 'Masukkan nama lengkap',
                      icon: Icons.person_outline,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _registerEmailController,
                    decoration: _inputDecoration(
                      label: 'Email Mahasiswa',
                      hint: 'nama@kampus.ac.id',
                      icon: Icons.email_outlined,
                      helper: 'Harus menggunakan email kampus (*.ac.id)',
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _registerPasswordController,
                    obscureText: true,
                    decoration: _inputDecoration(
                      label: 'Password',
                      hint: 'Minimal 8 karakter',
                      icon: Icons.lock_outline,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _registerConfirmPasswordController,
                    obscureText: true,
                    decoration: _inputDecoration(
                      label: 'Konfirmasi Password',
                      hint: 'Masukkan ulang password',
                      icon: Icons.lock_outline,
                    ),
                  ),

                  _buildError(_registerError),

                  const SizedBox(height: 20),

                  _buildButton(text: 'Daftar', onPressed: _handleRegister),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun?'),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = true;
                            _registerError = '';
                          });
                        },
                        child: const Text('Login'),
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
