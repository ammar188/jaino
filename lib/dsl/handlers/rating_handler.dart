import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../models/dsl_handler.dart';
import '../models/dsl_message.dart';
import '../models/dsl_render_result.dart';

class ReviewDSLHandler extends DSLHandler {
  @override
  String get type => 'review';

  @override
  int get version => 1;

  @override
  DSLRenderResult render(Event event, DSLMessage msg) {
    final menuItem = msg.get<String>('menu_item') ?? 'Leave Review';
    final orderId = msg.get<String>('order_id') ?? '';
    return DSLRenderResult(
      widget: _ReviewTriggerCard(
        menuItem: menuItem,
        orderId: orderId,
        room: event.room,
      ),
    );
  }
}

class _ReviewTriggerCard extends StatelessWidget {
  final String menuItem;
  final String orderId;
  final Room room;

  const _ReviewTriggerCard({
    required this.menuItem,
    required this.orderId,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showReviewSheet(context, room, menuItem, orderId),
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
                  'Leave Review',
                  style: TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  menuItem,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF111111), width: 0.83),
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

void _showReviewSheet(
    BuildContext context, Room room, String menuItem, String orderId) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: _ReviewSheet(
        room: room,
        menuItem: menuItem,
        orderId: orderId,
      ),
    ),
  );
}

class _ReviewSheet extends StatefulWidget {
  final Room room;
  final String menuItem;
  final String orderId;

  const _ReviewSheet({
    required this.room,
    required this.menuItem,
    required this.orderId,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0 || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    await widget.room.sendEvent(
      {
        'v': 1,
        'type': 'review_form',
        'data': {
          'order_id': widget.orderId,
          'menu_item': widget.menuItem,
          'rating': _rating,
          'comment': _commentCtrl.text.trim().isNotEmpty
              ? _commentCtrl.text.trim()
              : 'No comment',
        },
      },
      type: 'com.jaino.review_form',
    );

    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
      child: _submitted ? _buildThanks() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'How was your experience?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.menuItem,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 24),
        // Stars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.star,
                  size: 34,
                  color: i < _rating
                      ? const Color(0xFFFFC107)
                      : const Color(0xFFB7B9BC),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 28),
        // Comment field
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _commentCtrl,
            maxLines: 4,
            style: const TextStyle(fontSize: 13, color: Color(0xFF111111)),
            decoration: const InputDecoration(
              hintText: 'Write a comment (optional)',
              hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
              contentPadding: EdgeInsets.all(14),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Submit button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: GestureDetector(
            onTap: _rating > 0 ? _submit : null,
            child: Container(
              decoration: BoxDecoration(
                color: _rating > 0
                    ? const Color(0xFF7150DB)
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThanks() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFEDE8FB),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Color(0xFF7150DB),
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Thank you!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your review has been submitted.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}