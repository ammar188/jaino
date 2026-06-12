import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import '../models/dsl_handler.dart';
import '../models/dsl_message.dart';
import '../models/dsl_render_result.dart';

class OrderHistoryDSLHandler extends DSLHandler {
  @override
  String get type => 'order_history';

  @override
  int get version => 1;

  @override
  DSLRenderResult render(Event event, DSLMessage msg) {
    final orders = msg.get<List>('orders') ?? [];
    return DSLRenderResult(
      widget: _OrderHistoryTriggerCard(orders: orders),
    );
  }
}

class _OrderHistoryTriggerCard extends StatelessWidget {
  final List orders;
  const _OrderHistoryTriggerCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderHistoryPage(orders: orders),
        ),
      ),
      child: Container(
        width: 193.52,
        height: 64,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Order History',
                  style: TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${orders.length} order${orders.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            Container(
              width: 11.02,
              height: 11.02,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF111111),
                  width: 0.83,
                ),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF111111),
                size: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderHistoryPage extends StatefulWidget {
  final List orders;
  const OrderHistoryPage({required this.orders, super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String _filter = 'completed';

  List get _filtered => widget.orders.where((o) {
        final status = (o['status'] ?? '').toString().toLowerCase();
        if (_filter == 'completed')
          return status == 'paid' || status == 'completed';
        if (_filter == 'pending') return status == 'pending';
        if (_filter == 'cancelled') return status == 'cancelled';
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          width: 390,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(29, 0, 29, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back arrow
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF70737D),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 0.6,
                      ),
                      image: const DecorationImage(
                        image: AssetImage('assets/bot_avatar.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name + status
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dot',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          letterSpacing: -0.014,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34C759),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'AI Assistant Online',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              fontSize: 10,
                              letterSpacing: -0.011,
                              color: Color(0xFF70737D),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // const Spacer(),
                  // // Three dots
                  // const Icon(
                  //   Icons.more_vert,
                  //   color: Color(0xFF111111),
                  //   size: 20,
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Order History title + filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Order History',
                  style: TextStyle(
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 35,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 40),
              child: Row(
                children: [
                  _chip('Completed', 'completed'),
                  const SizedBox(width: 8),
                  _chip('Pending', 'pending'),
                  const SizedBox(width: 8),
                  _chip('Cancelled', 'cancelled'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Orders list
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No orders found',
                      style: TextStyle(color: Color(0xFF8E8E93)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = _filtered[index];
                      final status =
                          (order['status'] ?? '').toString().toLowerCase();
                      final isPaid =
                          status == 'paid' || status == 'completed';
                      final isCancelled = status == 'cancelled';

                      return Container(
                        width: 330,
                        height: 90,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Dot Cafe',
                                    style: TextStyle(
                                      color: Color(0xFF111111),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (order['items'] ?? '').toString(),
                                    style: const TextStyle(
                                      color: Color(0xFF8E8E93),
                                      fontSize: 8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  
                                  
                                      Text(
                                        'Rs ${order['total_amount']}',
                                        style: const TextStyle(
                                          color: Color(0xFF111111),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    
                                      Text(
                                        _formatDate(
                                            order['created_at'] ?? ''),
                                        style: const TextStyle(
                                          color: Color(0xFF8E8E93),
                                          fontSize: 8,
                                        ),
                                      ),
                                    
                                  
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? const Color(0xFF7150DB)
                                        : const Color(0xFFE0E0E0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isPaid
                                        ? 'Completed'
                                        : isCancelled
                                            ? 'Cancelled'
                                            : 'Pending',
                                    style: TextStyle(
                                      color: isPaid
                                          ? Colors.white
                                          : const Color(0xFF70737D),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                             
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.length >= 16) return raw.substring(0, 16);
    return raw;
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        width: 83,
        height: 35,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color:
              selected ? const Color(0xFF7150DB) : const Color(0xFFF2F2F4),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
  color: selected
      ? const Color(0xFF7150DB)
      : const Color(0x1C70737D),
  width: 0.6,
),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected ? Colors.white : const Color(0xFF70737D),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}