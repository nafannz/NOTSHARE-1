import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'auth_page.dart';
import 'note_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  bool _isCategoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchNotes();
  }

  // ========== FETCH CATEGORIES FROM DATABASE ==========
  Future<void> _fetchCategories() async {
    setState(() => _isCategoriesLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('id, name, semester, created_at')
          .order('name');
      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
        _isCategoriesLoading = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() => _isCategoriesLoading = false);
    }
  }

  // ========== FETCH NOTES ==========
  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final response = await supabase
            .from('notes')
            .select('*, categories(name)')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        setState(() {
          _notes = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching notes: $e');
      setState(() => _isLoading = false);
    }
  }

  // ========== GET NOTE COUNT PER CATEGORY ==========
  int _getNoteCountForCategory(String categoryId) {
    return _notes.where((note) => note['category_id'] == categoryId).length;
  }

  // ========== GET LAST UPDATE FOR CATEGORY ==========
  String _getLastUpdateForCategory(String categoryId) {
    final notesInCategory = _notes
        .where((note) => note['category_id'] == categoryId)
        .toList();
    if (notesInCategory.isEmpty) return 'Belum ada catatan';

    notesInCategory.sort((a, b) => b['created_at'].compareTo(a['created_at']));
    final lastUpdate = DateTime.parse(notesInCategory.first['created_at']);
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inDays >= 7) {
      return '${(difference.inDays / 7).floor()} minggu lalu';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${difference.inMinutes} menit lalu';
    }
  }

  // ========== LOGOUT ==========
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        // Arahkan ke AuthPage (Login/Register)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalNotes = _notes.length;
    final totalCategories = _categories.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchCategories();
          await _fetchNotes();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // ========== WELCOME & ACTION ==========
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat Datang,',
                        style: TextStyle(
                          color: AppColors.textSecond,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pelajar',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.textSecond,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ========== RINGKASAN AKTIVITAS ==========
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATISTIK BELAJARMU',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSummaryCard(
                          'Total Catatan',
                          totalNotes.toString(),
                        ),
                        _buildSummaryCard(
                          'Mata Kuliah',
                          totalCategories.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ========== CATATAN MATA KULIAH ==========
              Row(
                children: [
                  const Text(
                    'MATA KULIAH',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_categories.length} total',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecond,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // List Mata Kuliah dari Database
              if (_isCategoriesLoading)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              else if (_categories.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada mata kuliah',
                      style: TextStyle(color: AppColors.textSecond),
                    ),
                  ),
                )
              else
                ..._categories.map(
                  (category) => _buildSubjectCard(
                    category['name'],
                    '${_getNoteCountForCategory(category['id'])} catatan',
                    'Semester ${category['semester'] ?? '?'}',
                  ),
                ),

              const SizedBox(height: 28),

              // ========== CATATAN TERBARU ==========
              Row(
                children: [
                  const Text(
                    'CATATAN TERBARU',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_notes.length} total',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecond,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              else if (_notes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada catatan. Mari upload yang pertama!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecond),
                    ),
                  ),
                )
              else
                ..._notes.take(5).map((note) => _buildNoteCard(note)),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(String title, String subtitle, String semester) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Membuka mata kuliah: $title'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.book_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecond,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.textSecond,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        semester,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecond,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecond,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    // Ambil nama kategori dari relasi atau fallback
    String categoryName = 'Tanpa kategori';
    if (note['categories'] != null) {
      categoryName = note['categories']['name'] ?? 'Tanpa kategori';
    }

    String timeAgo = '';
    if (note['created_at'] != null) {
      final createdAt = DateTime.parse(note['created_at']);
      final difference = DateTime.now().difference(createdAt);
      if (difference.inDays >= 7) {
        timeAgo = '${(difference.inDays / 7).floor()}w ago';
      } else if (difference.inDays >= 1) {
        timeAgo = '${difference.inDays}d ago';
      } else if (difference.inHours >= 1) {
        timeAgo = '${difference.inHours}h ago';
      } else {
        timeAgo = '${difference.inMinutes}m ago';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoteDetailPage(note: note)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note['title'] ?? 'Tanpa judul',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              timeAgo,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecond),
            ),
          ],
        ),
      ),
    );
  }
}

// Import AuthPage untuk navigasi logout (tambahkan di bagian atas file)
// Jangan lupa tambahkan: import 'auth_page.dart';
