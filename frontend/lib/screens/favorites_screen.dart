import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/fade_in_slide.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<FavoritesProvider>(context, listen: false).fetchFavorites());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("My Favorites"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(child: SizedBox.expand()),
          Consumer<FavoritesProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF7C5CFF)));
              }

              if (provider.favorites.isEmpty) {
                return _buildEmptyState();
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: provider.favorites.length,
                itemBuilder: (context, index) {
                  final item = provider.favorites[index];
                  return _buildFavoriteCard(item);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text(
            "No Favorites Yet",
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Images you heart will appear here",
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(dynamic item) {
    return FadeInSlide(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          image: DecorationImage(
            image: NetworkImage(item['image_url']),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  Provider.of<FavoritesProvider>(context, listen: false).removeFavorite(item['id']);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
