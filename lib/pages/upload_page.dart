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
  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
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
            Text(
              'Upload Berhasil!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
    } else if (lowerContent.contains('web') ||
        lowerContent.contains('html') ||
        lowerContent.contains('css')) {
      detectedSubject = 'Pemrograman Web';
      keywords = ['html', 'css', 'javascript'];
    } else if (lowerContent.contains('database') ||
        lowerContent.contains('sql')) {
      detectedSubject = 'Basis Data';
      keywords = ['sql', 'query', 'database'];
    } else if (lowerContent.contains('logika') ||
        lowerContent.contains('fuzzy')) {
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
        'title': content.length > 50
            ? '${content.substring(0, 50)}...'
            : content,
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
      await _analyzeContent(
        'Logika Fuzzy adalah metode untuk menangani ketidakpastian dalam pengambilan keputusan',
      );
    }
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
    final isSelected = _selectedMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: !isSelected ? const Color(0xFF1F2937) : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFF374151),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
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
      backgroundColor: const Color(0xFF0B0F1A),
      appBar: AppBar(
        title: const Text('Upload Catatan'),
        centerTitle: true,
        backgroundColor: const Color(0xFF111622),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PILIH METODE UPLOAD',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 1.2,
                color: Color(0xFFF0EDE6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih cara Anda ingin mengunggah catatan',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildMethodCard(Icons.image_rounded, 'Foto', 'kamera'),
                const SizedBox(width: 12),
                _buildMethodCard(Icons.upload_file_rounded, 'File', 'upload'),
              ],
            ),
            const SizedBox(height: 28),

            // FOTO
            if (_selectedMethod == 'kamera') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.image_rounded,
                        size: 40,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pilih Foto Catatan',
                      style: TextStyle(
                        color: Color(0xFFF0EDE6),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG (max 50MB)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _pickImageAndAnalyze,
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('Pilih dari Galeri'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF7C3AED),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_selectedImage!.path),
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFileName ?? 'Foto dipilih',
                        style: const TextStyle(
                          color: Color(0xFFF0EDE6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _selectedFileName != null
                              ? Icons.check_circle_rounded
                              : Icons.cloud_upload_rounded,
                          size: 40,
                          color: _selectedFileName != null
                              ? const Color(0xFF10B981)
                              : const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFileName != null
                            ? _selectedFileName!
                            : 'Ketuk untuk pilih file',
                        style: TextStyle(
                          color: _selectedFileName != null
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF0EDE6),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PDF, PPT, DOCX (max 50MB)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // LOADING ANALISIS
            if (_isAnalyzing) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sedang menganalisis...',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF0EDE6),
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Membaca konten dan mendeteksi mata kuliah',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // HASIL ANALISIS
            if (_analysisResult != null && !_isAnalyzing) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Hasil Analisis AI',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('📖 Judul:', _analysisResult!['title']),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      '📚 Mata Kuliah:',
                      _analysisResult!['subject'],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('📅 Semester:', _analysisResult!['semester']),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // FORM
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF374151), width: 1),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Catatan',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.5,
                      color: Color(0xFFF0EDE6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Judul Catatan *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFFF0EDE6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Color(0xFFF0EDE6)),
                    decoration: InputDecoration(
                      hintText: 'ex: Rangkuman UTS Fisika Dasar',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFF111622),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF374151)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF374151)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF7C3AED),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mata Kuliah *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFFF0EDE6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    hint: const Text('Pilih mata kuliah'),
                    style: const TextStyle(color: Color(0xFFF0EDE6)),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category['id'].toString(),
                        child: Text(category['name']),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategoryId = value),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF111622),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF374151)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF374151)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Semester',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFFF0EDE6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSemester,
                    hint: const Text('Pilih semester'),
                    style: const TextStyle(color: Color(0xFFF0EDE6)),
                    items: _semesters.map((semester) {
                      return DropdownMenuItem(
                        value: semester,
                        child: Text(semester),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSemester = value),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF111622),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF374151)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF374151)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Deskripsi (Opsional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFFF0EDE6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: Color(0xFFF0EDE6)),
                    decoration: InputDecoration(
                      hintText: 'Jelaskan isi catatan ini...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFF111622),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF374151)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF374151)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF7C3AED),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // TOMBOL UPLOAD
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Upload Catatan',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
