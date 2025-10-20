import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<AppOrder> _cachedOrders = [];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('My Orders', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Color(0xFF10B981),
        elevation: 0,
      ),
      body: StreamBuilder<List<AppOrder>>(
        stream: OrderService().getCustomerOrders(user!.uid),
        builder: (context, snapshot) {
          // If we have data, update the cache
          if (snapshot.hasData) {
            _cachedOrders = snapshot.data!;
          }

          // Choose data source: cached or snapshot
          final orders = _cachedOrders;

          // Loading indicator only if first empty AND still waiting
          if (orders.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Empty state when truly empty after loading
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.grey.shade300),
                  SizedBox(height: 16),
                  Text('No orders yet', style: GoogleFonts.poppins(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text('Start shopping to see your orders here', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          // Show list from cache
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final AppOrder order;

  const OrderCard({required this.order});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Color(0xFFF59E0B);
      case 'confirmed':
        return Color(0xFF3B82F6);
      case 'delivered':
        return Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_outlined;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'delivered':
        return Icons.done_all;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt.toDate());

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Text('Order #${order.id.substring(0, 8)}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(_getStatusIcon(order.status), size: 14, color: _getStatusColor(order.status)),
                      SizedBox(width: 4),
                      Text(
                        order.status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: _getStatusColor(order.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                SizedBox(width: 6),
                Text(date, style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.address,
                    style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            // Timeline
            OrderTimeline(order: order),
            
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to order details screen
                },
                child: Text('View Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF10B981),
                  side: BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderTimeline extends StatelessWidget {
  final AppOrder order;

  const OrderTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildTimelineItem('Placed', true),
        _buildTimelineLine(order.status == 'confirmed' || order.status == 'delivered'),
        _buildTimelineItem('Confirmed', order.status == 'confirmed' || order.status == 'delivered'),
        _buildTimelineLine(order.status == 'delivered'),
        _buildTimelineItem('Delivered', order.status == 'delivered'),
      ],
    );
  }

  Widget _buildTimelineItem(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Color(0xFF10B981) : Colors.grey.shade300,
            border: Border.all(
              color: isActive ? Color(0xFF10B981) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Icon(
            isActive ? Icons.check : Icons.circle,
            size: 14,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? Color(0xFF10B981) : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 3,
        margin: EdgeInsets.only(bottom: 30),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF10B981) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
