import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/vto_provider.dart';
import '../utils/constants.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../providers/favorites_provider.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _reveal;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _reveal = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveToGallery(BuildContext context, String base64Image) async {
    try {
      final Uint8List bytes = base64Decode(base64Image);
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/VTO_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await Gal.putImage(filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image saved to gallery!'),
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

  Future<void> _shareImage(BuildContext context, String base64Image) async {
    try {
      final Uint8List bytes = base64Decode(base64Image);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/vto_share_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my virtual try-on with AuraFit AI!',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VtoProvider>(context);
    final result = provider.result;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Your Transformation"),
        backgroundColor: Colors.transparent,
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favProvider, _) {
              // Use the local path for favoriting since history is not on cloud
              final String imageUrl = provider.lastResultLocalPath ?? "";
              final isFav = favProvider.isFavorited(imageUrl);

              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? Colors.redAccent : Colors.white,
                ),
                onPressed: () {
                  if (imageUrl.isEmpty) return;
                  if (isFav) {
                    favProvider.removeFavorite(imageUrl);
                  } else {
                    favProvider.addFavorite(imageUrl);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.surface],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
                child: Column(
                  children: [
                    Container(
                      height: 520,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: FadeTransition(
                          opacity: _reveal,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.95, end: 1.0).animate(_reveal),
                            child: _buildResultImage(result),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Lookin' good!",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Your AI-fitted outfit is ready.",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.8),
                    border: const Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: "Save",
                              icon: Icons.download_rounded,
                              gradient: AppColors.secondaryGradient,
                              onPressed: () {
                                if (result?.resultImageBase64 != null) {
                                  _saveToGallery(context, result!.resultImageBase64!);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomButton(
                              text: "Share",
                              icon: Icons.ios_share_rounded,
                              color: AppColors.surface,
                              onPressed: () {
                                if (result?.resultImageBase64 != null) {
                                  _shareImage(context, result!.resultImageBase64!);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          provider.reset();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Try Another Outfit",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultImage(result) {
    if (result == null) return const Center(child: Text("No result"));

    if (result.resultImageBase64 != null) {
      return Image.memory(
        base64Decode(result.resultImageBase64!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error_outline_rounded)),
      );
    }

    return const Center(child: Text("Error loading image"));
  }
}
