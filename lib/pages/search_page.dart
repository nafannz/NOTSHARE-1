import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allNotes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  List<Map<String, dynamic>> _categories = [];
  
  String? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchNotes();
  }

  // ========== FETCH CATEGORIES FROM DATABASE ==========
  Future<void> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('id, name')
          .order('name');
      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
        // Tambahkan opsi "Semua" di awal
        _categories.insert(0, {'id': 'all', 'name': 'Semua'});
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  // ========== FETCH NOTES FROM DATABASE ==========
  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Ambil notes dengan join ke categories
      final response = await supabase
          .from('notes')
          .select('*, categories(id, name)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      setState(() {
        _allNotes = List<Map<String, dynamic>>.from(response);
        _filteredNotes = _allNotes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching notes: $e');
      setState(() => _isLoading = false);
    }
  }

  // ========== FILTER NOTES ==========
  void _filterNotes(String query) {
    setState(() {
      if (query.isEmpty && (_selectedCategoryId == null || _selectedCategoryId == 'all')) {
        _filteredNotes = _allNotes;
      } else {
        _filteredNotes = _allNotes.where((note) {
          // Filter by search query
          final title = note['title']?.toLowerCase() ?? '';
          final matchesSearch = title.contains(query.toLowerCase());
          
          // Filter by category
          bool matchesCategory = true;
          if (_selectedCategoryId != null && _selectedCategoryId != 'all') {
            matchesCategory = note['category_id'] == _selectedCategoryId;
          }
          
          return matchesSearch && matchesCategory;
        }).toList();
      }
    });
  }

  // ========== APPLY CATEGORY FILTER ==========
  void _applyCategoryFilter(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _filterNotes(_searchController.text);
    });
  }

  // ========== SHOW FILTER DIALOG ==========
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mata Kuliah:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId ?? 'all',
              hint: const Text('Pilih mata kuliah'),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category['id'].toString(),
                  child: Text(category['name']),
                );
              }).toList(),
              onChanged: (value) {
                _applyCategoryFilter(value);
                Navigator.pop(context);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Catatan'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchNotes();
          _filterNotes(_searchController.text);
        },
        child: Column(
          children: [
            // ========== SEARCH BAR ==========
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _filterNotes,
                decoration: InputDecoration(
                  hintText: 'Cari catatan...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showFilterDialog,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            // ========== FILTER ROW ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('FILTER:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategoryId ?? 'all',
                      hint: const Text('Semua'),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category['id'].toString(),
                          child: Text(category['name']),
                        );
                      }).toList(),
                      onChanged: (value) => _applyCategoryFilter(value),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ========== RESULT COUNT ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(
                    '${_filteredNotes.length} catatan',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // ========== LIST OF NOTES ==========
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredNotes.isEmpty
                      ? const Center(child: Text('Tidak ada catatan ditemukan'))
                      : ListView.builder(
                          itemCount: _filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = _filteredNotes[index];
                            // Ambil nama kategori dari relasi
                            String categoryName = 'Tanpa kategori';
                            if (note['categories'] != null) {
                              categoryName = note['categories']['name'] ?? 'Tanpa kategori';
                            }
                            // Status verifikasi (sementara semua dianggap terverifikasi)
                            final isVerified = true;
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                title: Text(
                                  note['title'] ?? 'Tanpa judul',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(categoryName),
                                trailing: isVerified
                                    ? const Chip(
                                        label: Text('Terverifikasi'),
                                        backgroundColor: Colors.green,
                                        labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                                      )
                                    : const Chip(
                                        label: Text('Belum Terverifikasi'),
                                        backgroundColor: Colors.grey,
                                        labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                onTap: () {
                                  // TODO: Navigasi ke detail catatan
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Fitur detail catatan sedang dikembangkan')),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}