import 'package:flutter/material.dart';
import 'kurir_home_page.dart';
import 'kurir_profile_page.dart';
import '../../widgets/notification_icon.dart';

class KurirContainerPage extends StatefulWidget {
  const KurirContainerPage({super.key});

  @override
  State<KurirContainerPage> createState() => _KurirContainerPageState();
}

class _KurirContainerPageState extends State<KurirContainerPage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const KurirHomePage(),
    const KurirProfilePage(),
  ];

  final List<String> _titles = [
    'ReuseMart Kurir',
    'Profil Kurir',
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