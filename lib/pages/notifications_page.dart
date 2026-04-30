import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('4 notifikasi belum dibaca', style: TextStyle(color: Colors.blue[600])),
          ),
          _buildNotificationCard(
            title: 'Upload Berhasil',
            message: 'Catatan \'Rangkuman UTS Fisika Dasar\' berhasil diupload',
            time: '5 menit lalu',
            isUnread: true,
          ),
          _buildNotificationCard(
            title: 'Catatan dari Kamera',
            message: 'Foto catatan \'Turunan Parsial\' berhasil diproses oleh AI',
            time: '1 jam lalu',
            isUnread: true,
          ),
          _buildNotificationCard(
            title: 'AI Sedang Memproses',
            message: 'AI sedang membaca dan mengelompokkan catatan \'Aljabar Linear\'',
            time: '2 jam lalu',
            isUnread: true,
            chipText: 'Diproses',
          ),
          _buildNotificationCard(
            title: 'Catatan Terverifikasi',
            message: 'Catatan \'Kalkulus 2 - Turunan\' telah diverifikasi oleh AI',
            time: '3 jam lalu',
            isUnread: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String time,
    required bool isUnread,
    String? chipText,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isUnread ? Border(left: BorderSide(color: Colors.blue[600]!, width: 4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (chipText != null) ...[
                const SizedBox(width: 8),
                Chip(label: Text(chipText), padding: EdgeInsets.zero),
              ],
            ],
          ),
        ],
      ),
    );
  }
}