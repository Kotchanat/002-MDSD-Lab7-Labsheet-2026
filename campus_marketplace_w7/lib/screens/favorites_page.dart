import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../repositories/favorites_repository.dart';

class FavoritesPage extends StatefulWidget {
  final FavoritesRepository repository;

  const FavoritesPage({
    super.key,
    required this.repository,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<FavoriteItem>> _favoritesFuture;

  @override
  void initState() {
    super.initState();

    _favoritesFuture = widget.repository.getAllFavorites();
  }

  // โหลดรายการโปรดใหม่
  void _reloadFavorites() {
    setState(() {
      _favoritesFuture = widget.repository.getAllFavorites();
    });
  }

  // ลบรายการโปรด
  Future<void> _removeFavorite(int itemId) async {
    try {
      await widget.repository.removeFavorite(itemId);

      if (!mounted) return;

      _reloadFavorites();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบรายการโปรดแล้ว'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เกิดข้อผิดพลาดในการลบรายการโปรด: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการโปรด'),
      ),
      body: FutureBuilder<List<FavoriteItem>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          // สถานะกำลังโหลด
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // สถานะเกิดข้อผิดพลาด
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'เกิดข้อผิดพลาดในการโหลดรายการโปรด:\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final favorites = snapshot.data ?? [];

          // สถานะไม่มีรายการโปรด
          if (favorites.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'ยังไม่มีรายการโปรด\n'
                  'ลองกดหัวใจที่หน้าหลักดูสิ',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // สถานะมีข้อมูล
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final item = favorites[index];

              return ListTile(
                leading: Image.network(
                  item.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const Icon(
                      Icons.broken_image,
                    );
                  },
                ),
                title: Text(item.title),
                subtitle: Text('${item.price} บาท'),
                trailing: IconButton(
                  tooltip: 'ลบรายการโปรด',
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _removeFavorite(item.itemId);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}