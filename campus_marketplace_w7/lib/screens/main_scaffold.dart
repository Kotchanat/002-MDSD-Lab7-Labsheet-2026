import 'package:flutter/material.dart';

import 'home_page.dart';
import 'sell_item_page.dart';
import 'favorites_page.dart';

import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/listing_draft_repository.dart';

class MainScaffold extends StatefulWidget {
  final ItemRepository itemRepository;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;

  const MainScaffold({
    super.key,
    required this.itemRepository,
    required this.favoritesRepository,
    required this.draftRepository,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomePage(
        repository: widget.itemRepository,
        favoritesRepository: widget.favoritesRepository,
        draftRepository: widget.draftRepository,
      ),
      SellItemPage(
        draftRepository: widget.draftRepository,
      ),
      FavoritesPage(
        repository: widget.favoritesRepository,
      ),
    ];
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;

      // สร้าง FavoritesPage ใหม่ทุกครั้งที่เปิด Tab รายการโปรด
      // เพื่อโหลดข้อมูลล่าสุดจาก Drift Database
      if (index == 2) {
        _pages[2] = FavoritesPage(
          repository: widget.favoritesRepository,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: 'ลงประกาศขาย',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'รายการโปรด',
          ),
        ],
      ),
    );
  }
}