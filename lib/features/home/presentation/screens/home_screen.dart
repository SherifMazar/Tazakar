import 'package:flutter/material.dart';

/// الشاشة الرئيسية - تحتوي على BottomNavigationBar و 3 تبويبات
/// StatefulWidget لتتبع التبويب النشط
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// رقم التبويب الحالي (0 = الرئيسية, 1 = الفئات, 2 = الإعدادات)
  int _currentIndex = 0;

  /// قائمة عناوين الشاشات
  final List<String> _titles = [
    'تذكر',           // الرئيسية
    'الفئات',         // الفئات
    'الإعدادات',      // الإعدادات
  ];

  /// قائمة محتوى كل تبويب (مؤقتة - سنبنيها لاحقاً)
  final List<Widget> _pages = [
    const _HomePage(),
    const _CategoriesPage(),
    const _SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // RTL للعربية
      child: Scaffold(
        // شريط العنوان
        appBar: AppBar(
          title: Text(_titles[_currentIndex]),
          centerTitle: true,
        ),
        
        // محتوى التبويب الحالي
        body: _pages[_currentIndex],
        
        // زر الإضافة العائم (Floating Action Button)
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: الانتقال لشاشة إضافة تذكير
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('إضافة تذكير - قريباً')),
            );
          },
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        
        // شريط التنقل السفلي
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            // تبويب الرئيسية
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            // تبويب الفئات
            BottomNavigationBarItem(
              icon: Icon(Icons.category),
              label: 'الفئات',
            ),
            // تبويب الإعدادات
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}

// ===== صفحات مؤقتة (Placeholder Pages) =====

/// صفحة الرئيسية المؤقتة
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_active,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تذكيرات حالياً',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر + لإضافة تذكير جديد',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// صفحة الفئات المؤقتة
class _CategoriesPage extends StatelessWidget {
  const _CategoriesPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'إدارة الفئات',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'قريباً',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// صفحة الإعدادات المؤقتة
class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'الإعدادات',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'قريباً',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
