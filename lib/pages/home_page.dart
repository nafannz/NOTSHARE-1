import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';

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
    final notesInCategory = _notes.where((note) => note['category_id'] == categoryId).toList();
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
      appBar: AppBar(
        title: const Text('NOTESHARE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchCategories();
          await _fetchNotes();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== SEARCH BAR ==========
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari catatan atau mata kuliah...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // ========== RINGKASAN AKTIVITAS ==========
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RINGKASAN AKTIVITAS', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildSummaryCard('Total Catatan', totalNotes.toString()),
                        _buildSummaryCard('Mata Kuliah', totalCategories.toString()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSummaryCard('AI Rekomendasi', '3'),
                        _buildSummaryCard('Lanjut Belajar', '2'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // ========== CATATAN MATA KULIAH ==========
              Row(
                children: [
                  const Text('CATATAN MATA KULIAH', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('(otomatis oleh AI)', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
              const SizedBox(height: 12),
              
              // List Mata Kuliah dari Database
              if (_isCategoriesLoading)
                const Center(child: CircularProgressIndicator())
              else if (_categories.isEmpty)
                const Center(child: Text('Belum ada mata kuliah'))
              else
                ..._categories.map((category) => _buildSubjectCard(
                  category['name'],
                  '${_getNoteCountForCategory(category['id'])} catatan · Semester ${category['semester'] ?? '?'}',
                  'Terakhir: ${_getLastUpdateForCategory(category['id'])}',
                )),
              
              const SizedBox(height: 24),
              
              // ========== CATATAN TERBARU ==========
              const Text('CATATAN TERBARU', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_notes.isEmpty)
                const Center(child: Text('Belum ada catatan. Upload dulu!'))
              else
                ..._notes.take(5).map((note) => _buildNoteCard(note)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubjectCard(String title, String subtitle, String lastUpdate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(lastUpdate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    // Ambil nama kategori dari relasi atau fallback
    String categoryName = 'Tanpa kategori';
    if (note['categories'] != null) {
      categoryName = note['categories']['name'] ?? 'Tanpa kategori';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note['title'] ?? 'Tanpa judul', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(categoryName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            note['created_at'] != null 
                ? DateTime.parse(note['created_at']).toString().substring(0, 16) 
                : '',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// Import AuthPage untuk navigasi logout (tambahkan di bagian atas file)
// Jangan lupa tambahkan: import 'auth_page.dart';