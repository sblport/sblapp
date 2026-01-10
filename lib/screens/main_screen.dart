import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'home_screen.dart';
import 'attendance_history_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AttendanceHistoryScreen(),
    const SizedBox(), // Placeholder for center Scanning/QRIS
    const Center(child: Text("For You Screen")), // Placeholder
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Navigate to Equipment Operations
      Navigator.pushNamed(context, '/operations');
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: Container(
        height: 64, 
        width: 64,
        margin: const EdgeInsets.only(top: 8), // Lift it up slightly if needed or just let it sit
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 4,
          onPressed: () => _onItemTapped(2),
          child: const Icon(Icons.agriculture, size: 28, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        color: AppColors.primary,
        clipBehavior: Clip.antiAlias,
        child: Container(
          height: 70, // Fixed height for navbar
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               _buildNavItem(0, Icons.home_rounded, "Home"),
               _buildNavItem(1, Icons.calendar_month, "Attendance"),
               
               // Center Space for FAB with Label below
               // Center Space for FAB
               const Spacer(),

               _buildNavItem(3, Icons.stars_rounded, "For You"), // Star icon
               _buildNavItem(4, Icons.person_rounded, "My Account"), // Profile icon matches
             ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;
    final Color color = isSelected ? Colors.white : Colors.white.withOpacity(0.6);

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
