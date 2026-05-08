import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/vto_provider.dart';
import '../providers/history_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/image_upload_card.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/error_card.dart';
import '../utils/app_colors.dart';
import 'result_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import '../widgets/app_sidebar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showImageSourceActionSheet(BuildContext context, bool isPerson) {
    final provider = Provider.of<VtoProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Take Photo', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  if (isPerson) {
                    provider.pickPersonImage(ImageSource.camera);
                  } else {
                    provider.pickClothImage(ImageSource.camera);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  if (isPerson) {
                    provider.pickPersonImage(ImageSource.gallery);
                  } else {
                    provider.pickClothImage(ImageSource.gallery);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppSidebar(),
      appBar: AppBar(
        title: const Text("AuraFit Premium"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Stack(
        children: [
          Consumer<VtoProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final name = auth.currentUser?.name ?? 'there';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back, $name",
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Ready for a transformation?",
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Step 1: Person Image
                    ImageUploadCard(
                      title: "Person Photo",
                      imageFile: provider.personImage,
                      icon: Icons.person_add_alt_1_rounded,
                      stepNumber: "1",
                      onTap: () => _showImageSourceActionSheet(context, true),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Step 2: Cloth Image
                    ImageUploadCard(
                      title: "Garment Image",
                      imageFile: provider.clothImage,
                      icon: Icons.shopping_bag_rounded,
                      stepNumber: "2",
                      onTap: () => _showImageSourceActionSheet(context, false),
                    ),

                    const SizedBox(height: 32),

                    // Step 3: Garment Type
                    const Row(
                      children: [
                        Icon(Icons.style_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Step 3: Garment Type",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _CategorySelector(
                      selected: provider.category,
                      onChanged: (cat) => provider.setCategory(cat),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Error Card if needed
                    if (provider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: ErrorCard(
                          message: provider.errorMessage!,
                          onRetry: () => provider.processTryOn(
                            historyProvider: Provider.of<HistoryProvider>(context, listen: false),
                          ),
                        ),
                      ),
                    
                    // Step 4: Generate
                    CustomButton(
                      text: "Step 4: Generate Try-On",
                      isLoading: provider.isLoading,
                      onPressed: () async {
                        final historyProvider =
                            Provider.of<HistoryProvider>(context, listen: false);
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        bool success = await provider.processTryOn(
                          historyProvider: historyProvider,
                          authProvider: authProvider,
                        );
                        if (success && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ResultScreen()),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Loading Overlay
          Consumer<VtoProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return LoadingOverlay(status: provider.loadingMessage);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategorySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      _CategoryOption('auto', 'Auto', Icons.auto_mode_rounded),
      _CategoryOption('tops', 'Tops', Icons.checkroom_rounded),
      _CategoryOption('bottoms', 'Bottoms', Icons.straighten_rounded),
      _CategoryOption('one-pieces', 'Full', Icons.accessibility_new_rounded),
    ];

    return Row(
      children: categories.map((cat) {
        final isSelected = selected == cat.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(cat.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(
                    cat.icon,
                    size: 20,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryOption {
  final String value;
  final String label;
  final IconData icon;

  _CategoryOption(this.value, this.label, this.icon);
}
