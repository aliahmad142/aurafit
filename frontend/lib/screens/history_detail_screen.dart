import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import '../models/history_item.dart';
import '../providers/history_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../services/database_helper.dart';

class HistoryDetailScreen extends StatelessWidget {
  final HistoryItem item;

  const HistoryDetailScreen({super.key, required this.item});

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      // Decrypt to a temporary file first
      final tempPath = await DatabaseHelper().decryptToTempFile(item.resultImagePath);
      await Gal.putImage(tempPath);
      
      // Cleanup temp file
      File(tempPath).delete().catchError((e) => debugPrint('Error deleting temp file: $e'));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved to gallery!'),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _shareImage(BuildContext context) async {
    try {
      // Decrypt to a temporary file first
      final tempPath = await DatabaseHelper().decryptToTempFile(item.resultImagePath);
      
      await Share.shareXFiles(
        [XFile(tempPath)],
        text: 'Check out my virtual try-on with AuraFit AI!',
      );

      // Note: temp file cleanup is harder with share_plus as we don't know when it's done.
      // Usually the OS cleans up temp directory eventually.
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Entry?'),
        content: const Text('This try-on will be permanently removed from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<HistoryProvider>(context, listen: false).deleteItem(item.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entry deleted'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Style Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          children: [
            // Source images side by side
            if (item.personImagePath != null || item.clothImagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    if (item.personImagePath != null)
                      Expanded(
                        child: _SourceThumbnail(
                          label: 'Source Person',
                          imagePath: item.personImagePath!,
                        ),
                      ),
                    if (item.personImagePath != null && item.clothImagePath != null)
                      const SizedBox(width: 16),
                    if (item.clothImagePath != null)
                      Expanded(
                        child: _SourceThumbnail(
                          label: 'Garment',
                          imagePath: item.clothImagePath!,
                        ),
                      ),
                  ],
                ),
              ),

            // Result image
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: FutureBuilder<Uint8List>(
                  future: DatabaseHelper().readImageFile(item.resultImagePath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox(
                        height: 300,
                        child: Center(child: Icon(Icons.broken_image_rounded, size: 48)),
                      );
                    }
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: "Save",
                    icon: Icons.download_rounded,
                    gradient: AppColors.secondaryGradient,
                    onPressed: () => _saveToGallery(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: "Share",
                    icon: Icons.ios_share_rounded,
                    color: AppColors.surface,
                    onPressed: () => _shareImage(context),
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

class _SourceThumbnail extends StatelessWidget {
  final String label;
  final String imagePath;

  const _SourceThumbnail({required this.label, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FutureBuilder<Uint8List>(
              future: DatabaseHelper().readImageFile(imagePath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Icon(Icons.broken_image_rounded));
                }
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
