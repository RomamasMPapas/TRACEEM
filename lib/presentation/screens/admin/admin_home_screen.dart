import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/user_entity.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../login_screen.dart';
import 'users_page.dart';
import 'complaints_page.dart';
import 'orders_management_page.dart';
import 'receipts_page.dart';
import 'ratings_page.dart';
import 'drivers_page.dart';
import 'dashboard_page.dart';

/// The main admin dashboard screen. Hosts Users, Orders, and Complaints tabs.
/// Adapts to wide screens with a [NavigationRail] and narrow screens with a [BottomNavigationBar].
class AdminHomeScreen extends StatefulWidget {
  final UserEntity admin;

  const AdminHomeScreen({super.key, required this.admin});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _setUserOnlineStatus(true);
  }

  @override
  void dispose() {
    _setUserOnlineStatus(false);
    super.dispose();
  }

  /// Updates the admin's `isOnline` field in Firestore to track their real-time online presence.
  Future<void> _setUserOnlineStatus(bool isOnline) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.admin.id)
          .update({'isOnline': isOnline});
    } catch (e) {
      print('Error updating admin online status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 600;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'TRACE EM ADMIN',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  widget.admin.username,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
              },
            ),
          ],
        ),
        body: Row(
          children: [
            if (isWide)
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                labelType: NavigationRailLabelType.all,
                backgroundColor: const Color(0xFFF5F5F5),
                selectedIconTheme: const IconThemeData(
                  color: Color(0xFF4C8CFF),
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF4C8CFF),
                  fontWeight: FontWeight.bold,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text('Users'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.shopping_bag_outlined),
                    selectedIcon: Icon(Icons.shopping_bag),
                    label: Text('Orders'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.report_gmailerrorred_outlined),
                    selectedIcon: Icon(Icons.report_gmailerrorred),
                    label: Text('Complaints'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: Text('Receipts'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.star_outline),
                    selectedIcon: Icon(Icons.star),
                    label: Text('Ratings'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.drive_eta_outlined),
                    selectedIcon: Icon(Icons.drive_eta),
                    label: Text('Drivers'),
                  ),
                ],
              ),
            const VerticalDivider(thickness: 1, width: 1),
            // Main Content
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  DashboardPage(),
                  UsersPage(),
                  OrdersManagementPage(),
                  ComplaintsPage(),
                  ReceiptsPage(),
                  RatingsPage(),
                  DriversPage(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: !isWide
            ? BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                selectedItemColor: const Color(0xFF4C8CFF),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people),
                    label: 'Users',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_bag),
                    label: 'Orders',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.report),
                    label: 'Complaints',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long),
                    label: 'Receipts',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.star),
                    label: 'Ratings',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.drive_eta),
                    label: 'Drivers',
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
