import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// شاشة التعريف بالتطبيق (Onboarding)
/// تعرض 3 شرائح توضح مميزات التطبيق
/// StatefulWidget لأنها تحتاج تتبع الشريحة الحالية
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// متحكم في PageView - يدير التنقل بين الشرائح
  final PageController _pageController = PageController();
  
  /// رقم الشريحة الحالية (0, 1, 2)
  int _currentPage = 0;

  /// قائمة الشرائح الثلاثة
  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      icon: Icons.mic,
      title: 'تحدث بصوتك',
      description: 'سجل تذكيراتك بصوتك باللهجة العربية المفضلة لديك',
    ),
    OnboardingSlide(
      icon: Icons.smart_toy,
      title: 'الذكاء الاصطناعي',
      description: 'يفهم طلبك ويحوله إلى تذكير تلقائياً بدون إنترنت',
    ),
    OnboardingSlide(
      icon: Icons.notifications_active,
      title: 'لن تنسى بعد اليوم',
      description: 'استلم إشعارات في الوقت المحدد لجميع مهامك',
    ),
  ];

  /// الانتقال للشريحة التالية أو للـ HomeScreen إذا كانت آخر شريحة
  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      // ننتقل للشريحة التالية بحركة سلسة
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // آخر شريحة - ننتقل للـ HomeScreen
      context.go('/home');
    }
  }

  /// تخطي الـ Onboarding والانتقال مباشرة للـ HomeScreen
  void _skipToHome() {
    context.go('/home');
  }

  /// تنظيف الموارد عند إغلاق الشاشة
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // RTL للعربية
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // زر "تخطي" في الأعلى يسار
              Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                  onPressed: _skipToHome,
                  child: const Text('تخطي'),
                ),
              ),
              
              // PageView - عرض الشرائح
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  // عند تغيير الشريحة - نحدث _currentPage
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlide(_slides[index]);
                  },
                ),
              ),
              
              // نقاط المؤشر (Page Indicator Dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => _buildDot(index),
                ),
              ),
              const SizedBox(height: 32),
              
              // زر "التالي" أو "ابدأ"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(
                      // إذا آخر شريحة: "ابدأ"، غير ذلك: "التالي"
                      _currentPage == _slides.length - 1 ? 'ابدأ' : 'التالي',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء شريحة واحدة
  Widget _buildSlide(OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // الأيقونة
          Icon(
            slide.icon,
            size: 120,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 48),
          
          // العنوان
          Text(
            slide.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // الوصف
          Text(
            slide.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء نقطة مؤشر واحدة
  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      // النقطة الحالية أكبر قليلاً
      width: _currentPage == index ? 12 : 8,
      height: 8,
      decoration: BoxDecoration(
        // النقطة الحالية لون كامل، البقية شفافة
        // تم تحديث: استخدام withValues بدلاً من withOpacity
        color: _currentPage == index
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// نموذج بيانات الشريحة الواحدة
class OnboardingSlide {
  final IconData icon;      // الأيقونة
  final String title;       // العنوان
  final String description; // الوصف

  OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });
}
