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
import '../widgets/home/track_view.dart';
import '../widgets/home/bottom_nav.dart';
import '../widgets/home/profile_view.dart';
import '../widgets/home/notifications_view.dart';
import 'debug_control_screen.dart';
import 'user_reports_screen.dart';

/// The main screen shown to an authenticated user.
/// Hosts the Book/Track tabs, notification badge, profile view, and the complaint/report button.
/// The [HomeScreen] class is responsible for managing its respective UI components and state.
class HomeScreen extends StatefulWidget {
  final UserEntity user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// The [_HomeScreenState] class is responsible for managing its respective UI components and state.
class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 0 for BOOK, 1 for TRACK
  bool _isProfileView = false;
  String? _detectedRegion;
  final GlobalKey<BookViewState> _bookViewKey = GlobalKey<BookViewState>();

  /// Initializes the screen by fetching orders, detecting the user's GPS region,
  /// and marking the user as online in Firestore.
  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(FetchOrders());
    _detectUserRegion();
    _setUserOnlineStatus(true);
  }

  /// Marks the user as offline in Firestore when they leave this screen.
  @override
  void dispose() {
    _setUserOnlineStatus(false);
    super.dispose();
  }

  /// Updates the user's `isOnline` field in Firestore to track their real-time online presence.
  /// Asynchronously executes the logic for _setUserOnlineStatus.
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

  /// Auto-detect user's region based on GPS location
  /// Asynchronously executes the logic for _detectUserRegion.
  Future<void> _detectUserRegion() async {
    try {
      final region = await LocationService.detectCurrentRegion();

      if (region != null && mounted) {
        setState(() {
          _detectedRegion = region.code;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Detected: ${region.name} (${region.code})'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        setState(() {
          _detectedRegion = 'Region 7';
        });
      }
    } catch (e) {
      print('Region detection error: $e');
      if (mounted) {
        setState(() {
          _detectedRegion = 'Region 7';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final currentUser = state is AuthAuthenticated
            ? state.user
            : widget.user;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4C8CFF), Color(0xFF3B6FCC)],
                ),
              ),
            ),
            elevation: 8,
            shadowColor: Colors.black26,
            centerTitle: true,
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_shipping, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  'TRACE EM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            leadingWidth: 70,
            leading: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('complaints')
                      .where('userId', isEqualTo: currentUser.id)
                      .where('status', isEqualTo: 'resolved')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final hasNewResponse =
                        snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              NotificationsDialog(user: currentUser),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: Color(0xFF3B6FCC),
                              size: 24,
                            ),
                          ),
                          if (hasNewResponse)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF4C8CFF),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.developer_mode, color: Colors.white),
                tooltip: 'Debug Console',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DebugControlScreen(),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: GestureDetector(
                  onTap: () => setState(() => _isProfileView = !_isProfileView),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Icon(Icons.person, color: Color(0xFF3B6FCC)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: _isProfileView
              ? ProfileView(user: currentUser)
              : (_currentIndex == 0
                    ? BookView(
                        key: _bookViewKey,
                        detectedRegion: _detectedRegion,
                      )
                    : const TrackView()),
          bottomNavigationBar: _isProfileView
              ? null
              : CustomBottomNav(
                  currentIndex: _currentIndex,
                  onTabSelected: (index) {
                    if (index == 0) {
                      _bookViewKey.currentState?.cancelBooking();
                    }
                    setState(() => _currentIndex = index);
                  },
                ),
          floatingActionButton: _isProfileView
              ? null
              : FloatingActionButton(
                  onPressed: () => _showComplaintDialog(context),
                  backgroundColor: const Color(0xFF4C8CFF),
                  child: const Icon(Icons.report_problem, color: Colors.white),
                ),
        );
      },
    );
  }

  /// Shows a dialog allowing the user to write and submit a complaint or report.
  /// Also provides a button to navigate to their report history.
  /// Executes the logic for _showComplaintDialog.
  void _showComplaintDialog(BuildContext context) {
    final controller = TextEditingController();
    // Capture the context of the HomeScreen for the push later
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
                Navigator.of(dialogContext).pop(); // Close dialog safely
                Navigator.push(
                  homeScreenContext, // Navigate from HomeScreen context
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

  /// Submits the user's complaint text to the Firestore 'complaints' collection.
  /// Shows a success or error snack bar depending on the result.
  /// Asynchronously executes the logic for _submitComplaint.
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
