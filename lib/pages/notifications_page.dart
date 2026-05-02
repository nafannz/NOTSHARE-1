import 'package:flutter/material.dart';
import '../main.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          const Text(
            'NOTIFIKASI',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '4 notifikasi belum dibaca',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _buildNotificationCard(
            title: 'Upload Berhasil',
            message: 'Catatan \'Rangkuman UTS Fisika Dasar\' berhasil diupload',
            time: '5 menit lalu',
            isUnread: true,
            icon: Icons.cloud_done_rounded,
            iconColor: AppColors.success,
          ),
          _buildNotificationCard(
            title: 'Catatan dari Foto',
            message:
                'Foto catatan \'Turunan Parsial\' berhasil diproses oleh AI',
            time: '1 jam lalu',
            isUnread: true,
            icon: Icons.image_rounded,
            iconColor: AppColors.primary,
          ),
          _buildNotificationCard(
            title: 'AI Sedang Memproses',
            message:
                'AI sedang membaca dan mengelompokkan catatan \'Aljabar Linear\'',
            time: '2 jam lalu',
            isUnread: true,
            chipText: 'Diproses',
            icon: Icons.auto_awesome_rounded,
            iconColor: AppColors.info,
          ),
          _buildNotificationCard(
            title: 'Catatan Terverifikasi',
            message:
                'Catatan \'Kalkulus 2 - Turunan\' telah diverifikasi oleh AI',
            time: '3 jam lalu',
            isUnread: true,
            icon: Icons.verified_rounded,
            iconColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String time,
    bool isUnread = false,
    String? chipText,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecond,
                    fontSize: 11,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.textSecond,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (chipText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          chipText,
                          style: const TextStyle(
                            color: AppColors.info,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
