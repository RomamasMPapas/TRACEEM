import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../core/services/location_service.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../widgets/home/book_view.dart';
import '../widgets/home/bottom_nav.dart';
import '../widgets/home/profile_view.dart';
import '../widgets/home/notifications_view.dart';
import '../widgets/home/history_view.dart';
import 'debug_control_screen.dart';
import 'user_reports_screen.dart';

/// The main screen shown to an authenticated user.
/// Hosts 4 tabs: HOME, NOTIFICATION, HISTORY, and PROFILE.
class HomeScreen extends StatefulWidget {
  final UserEntity user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 0: HOME, 1: NOTIFS, 2: HISTORY, 3: PROFILE
  String? _detectedRegion;
  final GlobalKey<BookViewState> _bookViewKey = GlobalKey<BookViewState>();

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(FetchOrders());
    _detectUserRegion();
    _setUserOnlineStatus(true);
  }

  @override
  void dispose() {
    _setUserOnlineStatus(false);
    super.dispose();
  }

  Future<void> _setUserOnlineStatus(bool isOnline) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'isOnline': isOnline});
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  Future<void> _detectUserRegion() async {
    try {
      final region = await LocationService.detectCurrentRegion();
      if (region != null && mounted) {
        setState(() => _detectedRegion = region.code);
      } else if (mounted) {
        setState(() => _detectedRegion = 'Region 7');
      }
    } catch (e) {
      print('Region detection error: $e');
      if (mounted) setState(() => _detectedRegion = 'Region 7');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final currentUser = state is AuthAuthenticated ? state.user : widget.user;

        return Scaffold(
          backgroundColor: Colors.white,
          // AppBar only shown for Home to keep Debug Console accessible
          appBar: _currentIndex == 0 ? AppBar(
            backgroundColor: const Color(0xFF4C8CFF),
            elevation: 0,
            title: const Text('TRACE EM', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.developer_mode, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DebugControlScreen())),
              ),
            ],
          ) : null,
          body: IndexedStack(
            index: _currentIndex,
            children: [
              // 0: HOME
              BookView(
                key: _bookViewKey,
                detectedRegion: _detectedRegion,
              ),
              // 1: NOTIFICATION
              NotificationsView(
                user: currentUser,
                onReportPressed: () => _showComplaintDialog(context),
              ),
              // 2: HISTORY
              HistoryView(
                onRebook: (fromName, fromCoords, toName, toCoords) {
                  setState(() => _currentIndex = 0);
                  // Brief delay to allow IndexedStack to switch before calling method
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _bookViewKey.currentState?.setLocations(
                      fromName: fromName,
                      fromCoords: fromCoords,
                      toName: toName,
                      toCoords: toCoords,
                    );
                  });
                },
              ),
              // 3: PROFILE
              ProfileView(user: currentUser),
            ],
          ),
          bottomNavigationBar: CustomBottomNav(
            currentIndex: _currentIndex,
            onTabSelected: (index) {
              if (index == 0 && _currentIndex == 0) {
                _bookViewKey.currentState?.cancelBooking();
              }
              setState(() => _currentIndex = index);
            },
          ),
        );
      },
    );
  }

  void _showComplaintDialog(BuildContext context) {
    final controller = TextEditingController();
    final homeScreenContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Submit Report'),
            IconButton(
              icon: const Icon(Icons.history, color: Color(0xFF4C8CFF)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  homeScreenContext,
                  MaterialPageRoute(
                    builder: (context) => UserReportsScreen(user: widget.user),
                  ),
                );
              },
              tooltip: 'View History',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe the issue you are experiencing.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter details...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _submitComplaint(controller.text);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C8CFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComplaint(String description) async {
    try {
      final user = widget.user;
      await FirebaseFirestore.instance.collection('complaints').add({
        'userId': user.id,
        'userName': user.username,
        'description': description,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
