import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/responsive_helper.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'start_visit_screen.dart';
import 'report_dashboard_screen_v2.dart';
import 'training/training_main_screen.dart';
// import 'training/training_dashboard_screen.dart'; // DISABLED - Focus on Daily Training

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // Check if user is trainer
  bool get _isTrainer => _currentUser?.role == 'trainer';

  // Check if user can access visit features
  bool get _canAccessVisit => !_isTrainer;

  // Check if user can access training features
  bool get _canAccessTraining =>
      _isTrainer ||
      _currentUser?.role == 'super_admin' ||
      _currentUser?.role == 'admin';

  Future<void> _loadCurrentUser() async {
    setState(() => _isLoading = true);

    final user = await _authService.getCurrentUser();

    if (!mounted) return;

    if (user == null) {
      // User not logged in, navigate to login
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _authService.logout();

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Responsive padding
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final isTabletMode = ResponsiveHelper.isTablet(context);
    final maxWidth = ResponsiveHelper.getCardMaxWidth(context);

    // Main content for Home tab
    Widget homeContent = Container(
      color: Colors.grey[50],
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? double.infinity,
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: isTabletMode ? 24 : 16),
                    // Welcome Banner
                    Padding(
                      padding: padding,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.7),
                              Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 24,
                              top: 24,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentUser!.name.split(' ').first,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_currentUser!.divisionName != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 5,
                                          sigmaY: 5,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.25,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.3,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            _currentUser!.divisionName!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: -20,
                              bottom: -20,
                              child: Icon(
                                Icons.store,
                                size: 140,
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Categories Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: _handleLogout,
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Icons - Role-Based (Responsive)
                ResponsiveBuilder(
                  builder: (context, constraints) {
                    final isTablet = ResponsiveHelper.isTablet(context);
                    
                    // For tablet, use grid layout in landscape
                    if (isTablet && ResponsiveHelper.isLandscape(context)) {
                      return Padding(
                        padding: padding,
                        child: GridView.count(
                          crossAxisCount: 5,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            // Visit - Only for non-trainers
                            if (_canAccessVisit)
                              _buildCategoryCard(
                                icon: Icons.checklist_rtl,
                                label: 'Visit',
                                color: Theme.of(context).primaryColor,
                                onTap: () => _onNavBarTapped(1),
                              ),

                            // Training - For trainers and admins
                            if (_canAccessTraining)
                              _buildCategoryCard(
                                icon: Icons.school,
                                label: 'Training',
                                color: Color(0xFF4A90E2),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TrainingMainScreen(),
                                    ),
                                  );
                                },
                              ),

                            // History - Only for non-trainers
                            if (_canAccessVisit)
                              _buildCategoryCard(
                                icon: Icons.history,
                                label: 'History',
                                color: Colors.green,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Coming soon')),
                                  );
                                },
                              ),

                            // Reports - Only for non-trainers
                            if (_canAccessVisit)
                              _buildCategoryCard(
                                icon: Icons.assessment,
                                label: 'Reports',
                                color: Colors.purple,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReportDashboardScreenV2(
                                        currentUser: _currentUser!,
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // Profile - Available for all
                            _buildCategoryCard(
                              icon: Icons.person,
                              label: 'Profile',
                              color: Colors.blueGrey,
                              onTap: () => _onNavBarTapped(2),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // Default horizontal scroll for mobile and tablet portrait
                    return SizedBox(
                      height: isTablet ? 120 : 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 12),
                        children: [
                          // Visit - Only for non-trainers
                          if (_canAccessVisit)
                            _buildCategoryIcon(
                              icon: Icons.checklist_rtl,
                              label: 'Visit',
                              color: Theme.of(context).primaryColor,
                              onTap: () => _onNavBarTapped(1),
                            ),

                          // Training - For trainers and admins
                          if (_canAccessTraining)
                            _buildCategoryIcon(
                              icon: Icons.school,
                              label: 'Training',
                              color: Color(0xFF4A90E2),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const TrainingMainScreen(),
                                  ),
                                );
                              },
                            ),

                          // History - Only for non-trainers
                          if (_canAccessVisit)
                            _buildCategoryIcon(
                              icon: Icons.history,
                              label: 'History',
                              color: Colors.green,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Coming soon')),
                                );
                              },
                            ),

                          // Reports - Only for non-trainers
                          if (_canAccessVisit)
                            _buildCategoryIcon(
                              icon: Icons.assessment,
                              label: 'Reports',
                              color: Colors.purple,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportDashboardScreenV2(
                                      currentUser: _currentUser!,
                                    ),
                                  ),
                                );
                              },
                            ),

                          // Profile - Available for all
                          _buildCategoryIcon(
                            icon: Icons.person,
                            label: 'Profile',
                            color: Colors.blueGrey,
                            onTap: () => _onNavBarTapped(2),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Features Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Main Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'View All',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Features Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: [
                      // Start Visit - Only for non-trainers
                      if (_canAccessVisit)
                        _buildFeatureCard(
                          title: 'Start Visit',
                          subtitle: 'Begin outlet inspection',
                          icon: Icons.play_circle_outline,
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                          ),
                          onTap: () => _onNavBarTapped(1),
                        ),

                      // InHouse Training - For trainers and admins
                      if (_canAccessTraining)
                        _buildFeatureCard(
                          title: 'InHouse Training',
                          subtitle: 'Training management',
                          icon: Icons.school_outlined,
                          gradient: LinearGradient(
                            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TrainingMainScreen(),
                              ),
                            );
                          },
                        ),

                      // Training Dashboard - DISABLED FOR NOW (Focus on Daily Training)
                      // if (_canAccessTraining)
                      //   _buildFeatureCard(
                      //     title: 'Training Dashboard',
                      //     subtitle: 'Statistics & reports',
                      //     icon: Icons.dashboard_customize_outlined,
                      //     gradient: LinearGradient(
                      //       colors: [Color(0xFF5B9BD5), Color(0xFF2E75B5)],
                      //     ),
                      //     onTap: () {
                      //       Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder: (context) =>
                      //               const TrainingDashboardScreen(),
                      //         ),
                      //       );
                      //     },
                      //   ),

                      // Reports - Only for non-trainers
                      if (_canAccessVisit)
                        _buildFeatureCard(
                          title: 'Reports',
                          subtitle: 'Analytics & insights',
                          icon: Icons.bar_chart,
                          gradient: LinearGradient(
                            colors: [Colors.purple[400]!, Colors.purple[600]!],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportDashboardScreenV2(
                                  currentUser: _currentUser!,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 80), // Space for bottom nav
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );

    // Profile tab content
    Widget profileContent = ProfileScreen(user: _currentUser!);

    // Start Visit tab content
    Widget startVisitContent = StartVisitScreen(currentUser: _currentUser!);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light background
      extendBody: true, // Make body extend behind navbar for floating effect
      body: _selectedIndex == 0
          ? homeContent
          : _selectedIndex == 1
          ? startVisitContent
          : _selectedIndex == 2
          ? profileContent
          : _selectedIndex == 3
          ? const TrainingMainScreen()
          : const SizedBox.shrink(),
      // Floating Bottom Navigation Bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white, // Clean white background
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(38),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                isSelected: _selectedIndex == 0,
              ),
              // Visit tab - Only for non-trainers
              if (_canAccessVisit)
                _buildNavItem(
                  icon: Icons.checklist_rtl_rounded,
                  label: 'Visit',
                  index: 1,
                  isSelected: _selectedIndex == 1,
                ),
              // Training tab - For trainers and admins
              if (_canAccessTraining)
                _buildNavItem(
                  icon: Icons.school_rounded,
                  label: 'Training',
                  index: 3,
                  isSelected: _selectedIndex == 3,
                ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                index: 2,
                isSelected: _selectedIndex == 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _onNavBarTapped(index),
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context)
                      .primaryColor // Primary blue color
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
              // Show label only when selected
              if (isSelected) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Card version for tablet grid layout
  Widget _buildCategoryCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    icon,
                    size: 100,
                    color: gradient.colors.first.withValues(alpha: 0.3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.colors.first.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: gradient.colors.last,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Coming Soon Badge Overlay
                if (isComingSoon)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 14,
                            color: gradient.colors.first,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Coming Soon',
                            style: TextStyle(
                              color: gradient.colors.first,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
