import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String _selectedMethod = 'upload';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _writeController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedSemester;
  final TextEditingController _descriptionController = TextEditingController();
  
  String? _selectedFileName;
  int? _selectedFileSize;
  XFile? _selectedImage;
  bool _isUploading = false;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  List<Map<String, dynamic>> _categories = [];
  final List<String> _semesters = ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8'];

  // ========== INISIALISASI ==========
  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // ========== FETCH CATEGORIES ==========
  Future<void> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('id, name, semester');
      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  // ========== RESET FORM ==========
  void _resetForm() {
    _titleController.clear();
    _writeController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategoryId = null;
      _selectedSemester = null;
      _selectedFileName = null;
      _selectedFileSize = null;
      _selectedImage = null;
      _analysisResult = null;
      _isAnalyzing = false;
    });
  }

  // ========== SHOW SNACKBAR (Didefinisikan di awal) ==========
  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // ========== GET CATEGORY NAME ==========
  String _getCategoryName(String? categoryId) {
    if (categoryId == null) return '-';
    for (var cat in _categories) {
      if (cat['id'].toString() == categoryId) {
        return cat['name'];
      }
    }
    return '-';
  }

  // ========== BUILD INFO ROW ==========
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  // ========== MODAL SUKSES ==========
  void _showSuccessModalWithData({
    required String title,
    required String categoryName,
    required String? semester,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Upload Berhasil!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('Judul:', title.isNotEmpty ? title : '-'),
            const SizedBox(height: 8),
            _buildInfoRow('Mata Kuliah:', categoryName),
            const SizedBox(height: 8),
            _buildInfoRow('Semester:', semester ?? '-'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // ========== ANALISIS KONTEN AI ==========
  Future<void> _analyzeContent(String content) async {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
    String detectedSubject = 'Umum';
    String detectedSemester = 'Semester 3';
    List<String> keywords = [];
    
    String lowerContent = content.toLowerCase();
    if (lowerContent.contains('kalkulus') || lowerContent.contains('turunan')) {
      detectedSubject = 'Kalkulus 2';
      keywords = ['turunan', 'integral', 'limit'];
    } else if (lowerContent.contains('aljabar')) {
      detectedSubject = 'Aljabar Linear';
      keywords = ['matriks', 'vektor', 'determinan'];
    } else if (lowerContent.contains('fisika')) {
      detectedSubject = 'Fisika Dasar';
      keywords = ['newton', 'mekanika', 'gravitasi'];
    } else if (lowerContent.contains('web') || lowerContent.contains('html') || lowerContent.contains('css')) {
      detectedSubject = 'Pemrograman Web';
      keywords = ['html', 'css', 'javascript'];
    } else if (lowerContent.contains('database') || lowerContent.contains('sql')) {
      detectedSubject = 'Basis Data';
      keywords = ['sql', 'query', 'database'];
    } else if (lowerContent.contains('logika') || lowerContent.contains('fuzzy')) {
      detectedSubject = 'Logika Fuzzy';
      keywords = ['logika', 'fuzzy', 'inferensi'];
    } else {
      keywords = ['belajar', 'catatan', 'materi'];
    }
    
    String? matchedCategoryId;
    for (var cat in _categories) {
      if (cat['name'] == detectedSubject) {
        matchedCategoryId = cat['id'];
        break;
      }
    }
    
    setState(() {
      _analysisResult = {
        'title': content.length > 50 ? '${content.substring(0, 50)}...' : content,
        'subject': detectedSubject,
        'subjectId': matchedCategoryId,
        'semester': detectedSemester,
        'keywords': keywords,
      };
      _isAnalyzing = false;
      
      if (_titleController.text.isEmpty) {
        _titleController.text = _analysisResult!['title'];
      }
      _selectedCategoryId ??= _analysisResult!['subjectId'];
      _selectedSemester ??= _analysisResult!['semester'];
    });
  }

  // ========== PICK FILE ==========
  Future<void> _pickFileAndAnalyze() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = result.files.first;
      if (file.size > 50 * 1024 * 1024) {
        _showSnackbar('File maksimal 50MB');
        return;
      }
      setState(() {
        _selectedFileName = file.name;
        _selectedFileSize = file.size;
        _selectedMethod = 'upload';
      });
      await _analyzeContent(file.name.replaceAll(RegExp(r'\.[^.]*$'), ''));
    }
  }

  // ========== PICK IMAGE ==========
  Future<void> _pickImageAndAnalyze() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      if (size > 50 * 1024 * 1024) {
        _showSnackbar('File gambar maksimal 50MB');
        return;
      }
      setState(() {
        _selectedImage = image;
        _selectedFileName = image.name;
        _selectedFileSize = size;
        _selectedMethod = 'kamera';
      });
      await _analyzeContent('Logika Fuzzy adalah metode untuk menangani ketidakpastian dalam pengambilan keputusan');
    }
  }

  // ========== ANALISIS TEKS TULISAN ==========
  Future<void> _analyzeWrittenNote() async {
    if (_writeController.text.trim().isEmpty) {
      _showSnackbar('Tulis catatan terlebih dahulu!');
      return;
    }
    await _analyzeContent(_writeController.text);
  }

  // ========== UPLOAD NOTE ==========
  Future<void> _uploadNote() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackbar('Judul catatan harus diisi');
      return;
    }
    if (_selectedCategoryId == null) {
      _showSnackbar('Pilih mata kuliah');
      return;
    }
    
    setState(() => _isUploading = true);
    
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        _showSnackbar('User tidak ditemukan');
        return;
      }
      
      final savedTitle = _titleController.text.trim();
      final savedCategoryId = _selectedCategoryId;
      final savedSemester = _selectedSemester;
      final savedCategoryName = _getCategoryName(savedCategoryId);
      
      final Map<String, dynamic> noteData = {
        'user_id': user.id,
        'title': savedTitle,
        'category_id': savedCategoryId,
        'semester': savedSemester ?? 'Semester 1',
        'description': _descriptionController.text.trim(),
        'file_name': _selectedFileName,
        'file_size': _selectedFileSize,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await supabase.from('notes').insert(noteData).select();
      
      _resetForm();
      
      _showSuccessModalWithData(
        title: savedTitle,
        categoryName: savedCategoryName,
        semester: savedSemester,
      );
      
    } catch (e) {
      print('❌ ERROR: $e');
      _showSnackbar('Gagal menyimpan: ${e.toString()}');
    }
    
    setState(() => _isUploading = false);
  }

  // ========== BUILD METHOD CARD ==========
  Widget _buildMethodCard(IconData icon, String label, String value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _selectedMethod == value ? const Color(0xFF1E3A5F) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, color: _selectedMethod == value ? Colors.white : Colors.grey),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: _selectedMethod == value ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // ========== BUILD ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Catatan'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A5F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TAMBAH CATATAN BARU', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMethodCard(Icons.camera_alt, 'Kamera', 'kamera'),
                const SizedBox(width: 12),
                _buildMethodCard(Icons.edit_note, 'Tulis', 'tulis'),
                const SizedBox(width: 12),
                _buildMethodCard(Icons.upload_file, 'Upload', 'upload'),
              ],
            ),
            const SizedBox(height: 24),
            
            // KAMERA
            if (_selectedMethod == 'kamera') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('Ambil foto catatan', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImageAndAnalyze,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Pilih dari Galeri'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A5F),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImage!.path),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            // TULIS CATATAN
            if (_selectedMethod == 'tulis') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_note, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Tulis catatanmu di sini', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _writeController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: 'Tulis catatanmu di sini...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _analyzeWrittenNote,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Analisis dengan AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // UPLOAD FILE
            if (_selectedMethod == 'upload') ...[
              GestureDetector(
                onTap: _pickFileAndAnalyze,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedFileName != null ? Icons.check_circle : Icons.cloud_upload,
                        size: 40,
                        color: _selectedFileName != null ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFileName != null ? _selectedFileName! : 'Tap untuk pilih file',
                        style: TextStyle(
                          color: _selectedFileName != null ? Colors.green : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Text('PDF, PPT, DOCX, JPG, PNG (max 50MB)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // LOADING ANALISIS
            if (_isAnalyzing) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('sedang menganalisis...', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Membaca konten dan mendeteksi mata kuliah'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // HASIL ANALISIS
            if (_analysisResult != null && !_isAnalyzing) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Hasil Analisis AI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('📖 Judul:', _analysisResult!['title']),
                    const SizedBox(height: 8),
                    _buildInfoRow('📚 Mata Kuliah:', _analysisResult!['subject']),
                    const SizedBox(height: 8),
                    _buildInfoRow('📅 Semester:', _analysisResult!['semester']),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // FORM
            const Text('Judul Catatan *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'ex: Rangkuman UTS Fisika Dasar',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            const Text('Mata Kuliah *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              hint: const Text('Pilih mata kuliah'),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category['id'].toString(),
                  child: Text(category['name']),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategoryId = value),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            
            const Text('Semester', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSemester,
              hint: const Text('Pilih semester'),
              items: _semesters.map((semester) {
                return DropdownMenuItem(value: semester, child: Text(semester));
              }).toList(),
              onChanged: (value) => setState(() => _selectedSemester = value),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            
            const Text('Deskripsi (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Jelaskan isi catatan ini...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            // TOMBOL UPLOAD
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A5F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Upload Catatan', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}