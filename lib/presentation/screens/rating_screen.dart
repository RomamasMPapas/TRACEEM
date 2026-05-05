import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


/// A premium dialog for users to rate their ride experience.
/// Includes driver info, star rating selection, and a comment section.
class RatingDialog extends StatefulWidget {
  final String driverName;
  final String vehicleInfo;
  final String driverPic;

  const RatingDialog({
    super.key,
    required this.driverName,
    required this.vehicleInfo,
    required this.driverPic,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

/// The [_RatingDialogState] class is responsible for managing its respective UI components and state.
class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  bool _blockDriver = false;
  final TextEditingController _commentController = TextEditingController();

  /// Builds the visual structure of this widget, returning the widget tree.
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      clipBehavior: Clip.antiAlias,
      elevation: 20,
      child: Container(
        width: 400,
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Gradient
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4C8CFF), Color(0xFF3B6FCC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "RATE YOUR RIDE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            "How was your trip today?",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              // Driver Pic + Info
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade100, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    widget.driverPic,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                widget.driverName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              Text(
                widget.vehicleInfo,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  bool isFull = index < _rating;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      transform: isFull ? (Matrix4.identity()..scale(1.1)) : Matrix4.identity(),
                      child: Icon(
                        isFull ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.orange,
                        size: 48,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              // Comment Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share your experience (Optional)',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Color(0xFF4C8CFF)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Block Driver Option
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Block this driver from future rides",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: _blockDriver,
                      activeColor: Colors.red,
                      onChanged: (val) {
                        setState(() => _blockDriver = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Submit Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: _rating == 0
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF4C8CFF), Color(0xFF3B6FCC)],
                            ),
                      color: _rating == 0 ? Colors.grey.shade300 : null,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: _rating == 0
                          ? null
                          : () async {
                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                // Fetch the actual username from Firestore (displayName is not set on signup)
                                String userName = 'Anonymous User';
                                if (user != null) {
                                  final userDoc = await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .get();
                                  userName = userDoc.data()?['username'] ?? user.email ?? 'Anonymous User';
                                }
                                
                                await FirebaseFirestore.instance.collection('ratings').add({
                                  'driver': widget.driverName,
                                  'user': userName,
                                  'rating': _rating,
                                  'comment': _commentController.text,
                                  'vehicle': widget.vehicleInfo,
                                  'type': widget.vehicleInfo.toLowerCase().contains('taxi') ? 'Taxi' : 'Motorcycle',
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'blocked': _blockDriver,
                                  'userId': user?.uid,
                                });

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Rating Submitted! Thank you.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: const Text(
                        "SUBMIT RATING",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Cleans up resources when the widget is permanently removed from the tree.
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
