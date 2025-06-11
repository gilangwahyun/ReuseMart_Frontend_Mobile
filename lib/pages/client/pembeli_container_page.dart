import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import './home_page.dart';
import './pembeli_profile_page.dart';
import './barang_detail_page.dart';

// Create a custom NavigatorObserver to detect route changes
class CustomNavigatorObserver extends NavigatorObserver {
  final Function(Route<dynamic>?, Route<dynamic>?) onRouteChanged;
  
  CustomNavigatorObserver({required this.onRouteChanged});
  
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onRouteChanged(newRoute, oldRoute);
  }
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged(route, previousRoute);
  }
}

class PembeliContainerPage extends StatefulWidget {
  const PembeliContainerPage({super.key});

  @override
  State<PembeliContainerPage> createState() => _PembeliContainerPageState();
}

class _PembeliContainerPageState extends State<PembeliContainerPage> {
  int _selectedIndex = 0;
  
  // Using PageController to manage pages without rebuilding them
  final PageController _pageController = PageController();
  
  // Create navigator observers to monitor route changes
  late List<CustomNavigatorObserver> _observers;
  
  // Keep the pages alive with GlobalKeys
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];
  
  // Keep track of page states
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    
    // Initialize observers
    _observers = List.generate(
      4,
      (index) => CustomNavigatorObserver(
        onRouteChanged: (newRoute, oldRoute) {
          // If we detect navigation to login page, propagate it to main app
          if (newRoute?.settings.name == AppRoutes.login) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                AppRoutes.navigateAndClear(context, AppRoutes.login);
              }
            });
          }
        },
      ),
    );
    
    _initPages();
  }

  void _initPages() {
    // Initialize the pages with Navigator widgets to maintain state
    _pages = [
      Navigator(
        key: _navigatorKeys[0],
        observers: [_observers[0]],
        onGenerateRoute: (RouteSettings settings) {
          print("DEBUG: Generating route for settings: ${settings.name}");
          
          // If this is the detail barang route
          if (settings.name == AppRoutes.detailBarang) {
            print("DEBUG: Handling detail barang route in container");
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args.containsKey('id_barang')) {
              final idBarang = args['id_barang'];
              return MaterialPageRoute(
                builder: (context) => BarangDetailPage(idBarang: idBarang),
                settings: settings,
              );
            }
          }
          
          // Default is the home page
          return MaterialPageRoute(
            builder: (BuildContext context) => const HomePage(isEmbedded: true),
            settings: settings,
          );
        },
      ),
      Navigator(
        key: _navigatorKeys[1],
        observers: [_observers[1]],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            builder: (BuildContext context) => const Scaffold(
              body: Center(child: Text('Cari')),
            ),
            settings: settings,
          );
        },
      ),
      Navigator(
        key: _navigatorKeys[2],
        observers: [_observers[2]],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            builder: (BuildContext context) => const Scaffold(
              body: Center(child: Text('Keranjang')),
            ),
            settings: settings,
          );
        },
      ),
      Navigator(
        key: _navigatorKeys[3],
        observers: [_observers[3]],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            builder: (BuildContext context) => const PembeliProfilePage(isEmbedded: true),
            settings: settings,
          );
        },
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // If tapping the current index, attempt to pop to root
    if (index == _selectedIndex) {
      final NavigatorState? navigator = _navigatorKeys[index].currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
        return;
      }
    }

    setState(() {
      _selectedIndex = index;
      // Change page without animation to avoid glitches
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final NavigatorState? navigator = _navigatorKeys[_selectedIndex].currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swiping
          children: _pages,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green.shade700,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Cari'),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Keranjang',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
} 