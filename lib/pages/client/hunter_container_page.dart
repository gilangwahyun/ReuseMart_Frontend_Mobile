import 'package:flutter/material.dart';
import 'hunter_home_page.dart';
import 'hunter_profile_page.dart';
import '../../widgets/notification_icon.dart';

class HunterContainerPage extends StatefulWidget {
  const HunterContainerPage({super.key});

  @override
  State<HunterContainerPage> createState() => _HunterContainerPageState();
}

class _HunterContainerPageState extends State<HunterContainerPage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const HunterHomePage(),
    const HunterProfilePage(),
  ];

  final List<String> _titles = [
    'ReuseMart Hunter',
    'Profil Hunter',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.green.shade600,
        actions: [
          NotificationIcon(color: Colors.white, badgeColor: Colors.amber),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green.shade700,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
} 