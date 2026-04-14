import 'package:flutter/material.dart';
import 'item_listing_page.dart';
import 'home_page.dart';
import 'profile_page.dart' as profile;
import 'chat_list_page.dart';
import 'request_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0; // Discover tab selected by default
  DateTime? _lastBackPressTime;

  // Placeholder pages for other navigation items
  final List<Widget> _pages = [
    const HomePage(),
    const RequestPage(),
    const ItemListingPage(),
    const ChatPage(),
    const ProfilePage(),
  ];

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    const exitTimeLimit = Duration(seconds: 2);

    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > exitTimeLimit) {
      // First back press or timeout - show message
      _lastBackPressTime = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit the app'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return false; // Don't exit
    } else {
      // Second back press within timeout - allow exit
      return true; // Exit
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          bool shouldExit = await _onWillPop();
          if (shouldExit && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.02,
                vertical: screenHeight * 0.01,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.explore_outlined,
                    label: 'Discover',
                    index: 0,
                    screenWidth: screenWidth,
                  ),
                  _buildNavItem(
                    icon: Icons.sync_alt,
                    label: 'Request',
                    index: 1,
                    screenWidth: screenWidth,
                  ),
                  _buildNavItem(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Items',
                    index: 2,
                    screenWidth: screenWidth,
                  ),
                  _buildNavItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    index: 3,
                    screenWidth: screenWidth,
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    index: 4,
                    screenWidth: screenWidth,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required double screenWidth,
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFFFF6B6B) : Colors.grey;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: screenWidth * 0.065),
          SizedBox(height: screenWidth * 0.01),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: screenWidth * 0.03,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder pages

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatListPage();
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const profile.ProfilePage();
  }
}
