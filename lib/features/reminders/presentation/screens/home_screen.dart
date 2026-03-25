import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    if (index == 2) {
      context.goNamed('settings');
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF2E7D8C);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تذكر',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: tealColor,
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _RemindersTabPlaceholder(),
          _CategoriesTabPlaceholder(),
          _SettingsTabPlaceholder(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: tealColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.mic_rounded),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: tealColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _RemindersTabPlaceholder extends StatelessWidget {
  const _RemindersTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Reminders',
        style: TextStyle(fontFamily: 'Cairo', fontSize: 24),
      ),
    );
  }
}

class _CategoriesTabPlaceholder extends StatelessWidget {
  const _CategoriesTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Categories',
        style: TextStyle(fontFamily: 'Cairo', fontSize: 24),
      ),
    );
  }
}

class _SettingsTabPlaceholder extends StatelessWidget {
  const _SettingsTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Settings',
        style: TextStyle(fontFamily: 'Cairo', fontSize: 24),
      ),
    );
  }
}
