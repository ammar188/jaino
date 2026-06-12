import 'package:fluffychat/config/themes.dart';
import 'package:flutter/material.dart';
import 'payments.dart';

class PaymentsView extends StatelessWidget {
  final PaymentsController controller;

  const PaymentsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: PreferredSize(
  preferredSize: const Size(390, 110),
 child: Container(
  width: 390,
  color: Colors.white,
  child: SafeArea(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        if (!FluffyThemes.isColumnMode(context))
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF70737D),
              size: 16,
            ),
          ),
        Expanded(
          child: Center(
            child: const Text(
              'Payment',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF111111),
              ),
            ),
          ),
        ),
        if (!FluffyThemes.isColumnMode(context))
          const SizedBox(width: 16),
      ],
    ),
  ),
),
  ),
),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Filter chips
          SizedBox(
            height: 35,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _Chip('All', 'all', controller),
                  const SizedBox(width: 8),
                  _Chip('Paid', 'paid', controller),
                  const SizedBox(width: 8),
                  _Chip('Pending', 'pending', controller),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List
          Expanded(
            child: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : controller.payments.isEmpty
                    ? const Center(
                        child: Text(
                          'No payments found',
                          style: TextStyle(color: Color(0xFF8E8E93)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: controller.payments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final p = controller.payments[index];
                          final status =
                              (p['status'] ?? '').toString().toLowerCase();
                          final isPaid = status == 'paid';
                          final isFailed = status == 'failed';

                          return Container(
                            width: 330,
                            height: 100,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Text info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
  p['business_name'] ?? 'Unknown Business',
  style: const TextStyle(
    color: Color(0xFF111111),
    fontSize: 12,
    fontWeight: FontWeight.w500,
  ),
),

                                      const SizedBox(height: 2),
                                      Text(
                                        'Order #${p['order_id'] ?? ''}',
                                        style: const TextStyle(
                                          color: Color(0xFF8E8E93),
                                          fontSize: 8,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rs ${p['amount']}',
                                        style: const TextStyle(
                                          color: Color(0xFF111111),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(
                                            p['created_at'] ?? ''),
                                        style: const TextStyle(
                                          color: Color(0xFF8E8E93),
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? const Color(0xFF7150DB)
                                        : isFailed
                                            ? const Color(0xFFE53935)
                                            : const Color(0xFFE0E0E0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isPaid
                                        ? 'Paid'
                                        : isFailed
                                            ? 'Failed'
                                            : 'Pending',
                                    style: TextStyle(
                                      color: isPaid || isFailed
                                          ? Colors.white
                                          : const Color(0xFF70737D),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
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
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final PaymentsController controller;

  const _Chip(this.label, this.value, this.controller);

  @override
  Widget build(BuildContext context) {
    final selected = controller.filter == value;
    return GestureDetector(
      onTap: () => controller.setFilter(value),
      child: Container(
        width: 83,
        height: 35,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF7150DB)
              : const Color(0xFFF2F2F4),
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
              color: selected ? Colors.white : const Color(0xFF70737D),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}