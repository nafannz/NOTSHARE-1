import 'package:flutter/material.dart';

class NoteDetailPage extends StatefulWidget {
  final Map<String, dynamic> note;

  const NoteDetailPage({required this.note, super.key});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  @override
  Widget build(BuildContext context) {
    String categoryName = 'Tanpa kategori';
    if (widget.note['categories'] != null) {
      categoryName = widget.note['categories']['name'] ?? 'Tanpa kategori';
    }

    final createdAt = widget.note['created_at'] != null
        ? DateTime.parse(widget.note['created_at'])
        : DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Catatan'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul
            Text(
              widget.note['title'] ?? 'Tanpa judul',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Kategori Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                categoryName,
                style: const TextStyle(color: Colors.blue, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Info baris
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                if (widget.note['file_size'] != null)
                  Row(
                    children: [
                      Icon(Icons.storage, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${(widget.note['file_size'] / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Deskripsi
            if (widget.note['description'] != null &&
                widget.note['description'].isNotEmpty) ...[
              const Text(
                'Deskripsi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.note['description']),
              ),
              const SizedBox(height: 24),
            ],

            // Informasi File
            if (widget.note['file_name'] != null) ...[
              const Text(
                'Informasi File',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file,
                      color: Colors.blue[600],
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.note['file_name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.note['file_size'] != null)
                            Text(
                              '${(widget.note['file_size'] / 1024).toStringAsFixed(1)} KB',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Semester (jika ada)
            if (widget.note['semester'] != null) ...[
              const Text(
                'Semester',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.note['semester'],
                  style: TextStyle(color: Colors.green[700]),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur download sedang dikembangkan'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur share sedang dikembangkan'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Bagikan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
