import 'package:flutter/material.dart';
import 'penitip_home_page.dart';
import 'penitip_profile_page.dart';
import '../../widgets/notification_icon.dart';
import '../../routes/app_routes.dart';

class PenitipContainerPage extends StatefulWidget {
  const PenitipContainerPage({super.key});

  @override
  State<PenitipContainerPage> createState() => _PenitipContainerPageState();
}

class _PenitipContainerPageState extends State<PenitipContainerPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const PenitipHomePage(isEmbedded: true),
    const PenitipProfilePage(isEmbedded: true),
  ];

  final List<String> _titles = ['ReuseMart Penitip', 'Profil Penitip'];

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
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.settings);
              },
            ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
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
