import 'package:flutter/material.dart';
import 'package:tiklarm/screens/alarm_list_screen.dart';
import 'package:tiklarm/screens/world_clock_screen.dart';
import 'package:tiklarm/screens/timer_screen.dart';
import 'package:tiklarm/screens/stopwatch_screen.dart';
import 'package:tiklarm/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiklarm/services/theme_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = const [
    AlarmListScreen(showAppBar: false),
    WorldClockScreen(),
    TimerScreen(),
    StopwatchScreen(),
  ];

  final List<String> _titles = [
    'Tiklarm',
    'World Clock',
    'Timer',
    'Stopwatch',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _screens.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
    
    // Initialize fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );
    _fadeController.value = 1.0; // Start fully visible
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  // Method to animate tab changes
  void _animateToTab(int index) {
    if (_selectedIndex == index) return;
    
    _fadeController.reverse().then((_) {
      setState(() {
        _selectedIndex = index;
        _tabController.animateTo(index, 
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      });
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.25),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _titles[_selectedIndex],
            key: ValueKey<String>(_titles[_selectedIndex]),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return ScaleTransition(
                scale: Tween<double>(
                  begin: 0.9,
                  end: 1.0,
                ).animate(
                  CurvedAnimation(
                    parent: _fadeController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              );
            },
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      var curve = Curves.easeOutCubic;
                      var curveTween = CurveTween(curve: curve);
                      
                      var fadeAnimation = Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(animation.drive(curveTween));
                      
                      var slideAnimation = Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(animation.drive(curveTween));
                      
                      return FadeTransition(
                        opacity: fadeAnimation,
                        child: SlideTransition(
                          position: slideAnimation,
                          child: child,
                        ),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                ).then((_) {
                  // Refresh theme settings after returning from settings screen
                  ThemeService().refreshFromPrefs();
                });
              },
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: _screens,
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        margin: const EdgeInsets.only(top: 15),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            currentIndex: _selectedIndex,
            onTap: _animateToTab,
            elevation: 0,
            items: List.generate(4, (index) {
              final isSelected = index == _selectedIndex;
              return BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(isSelected ? 5.0 : 0.0),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildNavIcon(index, isSelected),
                ),
                label: _getNavLabel(index),
              );
            }),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavIcon(int index, bool isSelected) {
    const double selectedSize = 28.0;
    const double unselectedSize = 24.0;
    
    IconData getIcon(int idx) {
      switch (idx) {
        case 0: return isSelected ? Icons.alarm : Icons.alarm_outlined;
        case 1: return isSelected ? Icons.public : Icons.public_outlined;
        case 2: return isSelected ? Icons.timer : Icons.timer_outlined;
        case 3: return isSelected ? Icons.watch : Icons.watch_outlined;
        default: return Icons.error;
      }
    }
    
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Icon(
        getIcon(index),
        size: isSelected ? selectedSize : unselectedSize,
      ),
    );
  }
  
  String _getNavLabel(int index) {
    switch (index) {
      case 0: return 'Alarm';
      case 1: return 'World';
      case 2: return 'Timer';
      case 3: return 'Stopwatch';
      default: return '';
    }
  }
} 