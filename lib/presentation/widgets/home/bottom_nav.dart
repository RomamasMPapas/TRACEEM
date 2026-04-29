import 'package:flutter/material.dart';

/// Custom bottom navigation bar for the Home screen with BOOK and TRACK tabs.
/// Also shows a branded TRACE EM footer bar with a truck icon below the tabs.
/// The [CustomBottomNav] class is responsible for managing its respective UI components and state.
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabSelected(0),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 20,
                          color: currentIndex == 0
                              ? Colors.black
                              : Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BOOK',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: currentIndex == 0
                                ? Colors.black
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabSelected(1),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 20,
                          color: currentIndex == 1
                              ? Colors.black
                              : Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TRACK',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: currentIndex == 1
                                ? Colors.black
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          height: 80,
          color: const Color(0xFF4C8CFF),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'TRACE EM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 5),
              const Icon(Icons.local_shipping, color: Colors.white, size: 30),
            ],
          ),
        ),
      ],
    );
  }
}
