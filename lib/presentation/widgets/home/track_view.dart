import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/order_bloc.dart';
import '../../bloc/order_event.dart';
import '../../bloc/order_state.dart';
import '../../screens/order_tracking_screen.dart';

class TrackView extends StatelessWidget {
  const TrackView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is OrdersLoaded) {
          if (state.orders.isEmpty) {
            return const Center(
              child: Text(
                'No active orders found.\nGo to Debug to create one!',
              ),
            );
          }
          return ListView.builder(
            itemCount: state.orders.length,
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final order = state.orders[index];
              // Assign distance color for demo
              Color distColor = Colors.greenAccent;
              if (index == 0) distColor = const Color(0xFFFF8A8A); // Reddish
              if (index == 2) distColor = const Color(0xFFFFCC80); // Orange
              if (index > 2)
                distColor = const Color(
                  0xFF64B5F6,
                ); // Blue for live tracked orders

              return Padding(
                padding: const EdgeInsets.only(bottom: 25.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderTrackingScreen(
                          region: order.region,
                          orderIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: const Icon(Icons.inventory_2_outlined),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: distColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order #${order.orderNumber}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '📍 ${order.region}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        if (state is OrderError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                Text('Error: ${state.message}'),
                ElevatedButton(
                  onPressed: () => context.read<OrderBloc>().add(FetchOrders()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('No orders found'));
      },
    );
  }
}
