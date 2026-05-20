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
    final menuItem = msg.get<String>('menu_item') ?? 'Your Order';
    final orderId = msg.get<String>('order_id') ?? '';

    return DSLRenderResult(
      widget: _ReviewTriggerButton(
        menuItem: menuItem,
        orderId: orderId,
        room: event.room,
      ),
    );
  }
}

// ── Trigger Button ────────────────────────────────────────────────────────────
class _ReviewTriggerButton extends StatelessWidget {
  final String menuItem;
  final String orderId;
  final Room room;

  const _ReviewTriggerButton({
    required this.menuItem,
    required this.orderId,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final titleColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final subtitleColor = const Color(0xFFC9C9C9);
    final btnBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final btnText = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return GestureDetector(
      onTap: () => _showReviewModal(context, menuItem, orderId, room),
      child: Container(
        width: 193,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15.14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⭐ Rate Your Order',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              menuItem,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 9,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 0.60,
              color: subtitleColor.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 32,
              decoration: BoxDecoration(
                color: btnBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: subtitleColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tap to review',
                    style: TextStyle(
                      color: btnText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_circle_right, color: btnText, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Show Modal ────────────────────────────────────────────────────────────────
void _showReviewModal(
    BuildContext context, String menuItem, String orderId, Room room) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReviewBottomSheet(menuItem: menuItem, orderId: orderId, room: room),
  );
}

// ── Bottom Sheet ──────────────────────────────────────────────────────────────
class _ReviewBottomSheet extends StatefulWidget {
  final String menuItem;
  final String orderId;
  final Room room;

  const _ReviewBottomSheet({
    required this.menuItem,
    required this.orderId,
    required this.room,
  });

  @override
  State<_ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<_ReviewBottomSheet> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();

  final List<String> _ratingLabels = [
    '',
    'Terrible',
    'Bad',
    'Okay',
    'Good',
    'Excellent',
  ];


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final primaryText = isDark ? const Color(0xFF272727) : Colors.white;
    final secondaryText = const Color(0xFF8E8E93);
    final dividerColor = isDark ? const Color(0xFFD9D9D9) : const Color(0xFF3A3A3C);
    final dragColor = const Color(0xFFD9D9D9);
    final submitBg = isDark ? const Color(0xFF111111) : Colors.white;
    final submitText = isDark ? Colors.white : const Color(0xFF111111);
    final inputBg = isDark ? const Color(0xFFF2F2F7) : const Color(0xFF2C2C2E);
    final inputText = isDark ? const Color(0xFF272727) : Colors.white;
    final inputHint = secondaryText;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: 388.39,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28.43)),
        ),
        padding: const EdgeInsets.all(21.87),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ───────────────────────────────────────────────
            Center(
              child: Container(
                width: 80.92,
                height: 4.37,
                decoration: BoxDecoration(
                  color: dragColor,
                  borderRadius: BorderRadius.circular(13.12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Header ────────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate Your Order',
                    style: TextStyle(
                      color: primaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.menuItem,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(width: double.infinity, height: 0.28, color: dividerColor),

            const SizedBox(height: 20),

            // ── Stars ─────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      star <= _selectedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: star <= _selectedRating
                          ? const Color(0xFFFFCC00)
                          : secondaryText,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // ── Rating label ──────────────────────────────────────────────
            if (_selectedRating > 0)
              Text(
                _ratingLabels[_selectedRating],
                style: const TextStyle(
                  color: Color(0xFFFFCC00),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

            const SizedBox(height: 20),

            // ── Comment box ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 3,
                style: TextStyle(color: inputText, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Write your comment here...',
                  hintStyle: TextStyle(color: inputHint, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Submit button ─────────────────────────────────────────────
            if (_selectedRating > 0)
              GestureDetector(
                onTap: () async {
  final comment = _commentController.text.trim();
  Navigator.of(context).pop();
  await widget.room.sendEvent(
    {
      'menu_item': widget.menuItem,
      'order_id': widget.orderId,
      'rating': _selectedRating,
      'comment': comment.isEmpty ? 'none' : comment,
    },
    type: 'com.jaino.review_submit',
  );
},
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: submitBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Submit Review',
                      style: TextStyle(
                        color: submitText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}