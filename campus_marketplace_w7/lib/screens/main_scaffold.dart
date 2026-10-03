
import 'package:flutter/material.dart';

import 'home_page.dart';
import 'sell_item_page.dart';
import '../repositories/item_repository.dart';

class MainScaffold extends StatefulWidget {
  final ItemRepository repository;

  const MainScaffold({
    super.key,
    required this.repository,
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

    // สร้างหน้าแต่ละแท็บเพียงครั้งเดียว
    _pages = [
      HomePage(repository: widget.repository),
      const SellItemPage(),
    ];
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: 'ลงประกาศขาย',
          ),
        ],
      ),
    );
  }
}