import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../models/dsl_handler.dart';
import '../models/dsl_message.dart';
import '../models/dsl_render_result.dart';

class MenuDSLHandler extends DSLHandler {
  @override
  String get type => 'menu';

  @override
  int get version => 1;

  @override
  DSLRenderResult render(Event event, DSLMessage msg) {
    final title = msg.get<String>('title') ?? 'Menu';
    final items = msg.get<List>('items') ?? [];

    return DSLRenderResult(
      widget: _MenuTriggerButton(title: title, items: items, room: event.room),
    );
  }
}

// ── Trigger Button ────────────────────────────────────────────────────────────
class _MenuTriggerButton extends StatelessWidget {
  final String title;
  final List items;
  final Room room;

  const _MenuTriggerButton({required this.title, required this.items, required this.room});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // light mode = black card, dark mode = white card
    final cardColor = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final titleColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final subtitleColor = isDark ? const Color(0xFFC9C9C9) : const Color(0xFFC9C9C9);
    final dividerColor = isDark ? const Color(0xFFC9C9C9) : const Color(0xFFC9C9C9);
    final tapBgColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFF1F1F1F);
    final tapTextColor = Colors.white;

    return GestureDetector(
      onTap: () => _showMenuModal(context, title, items, room),
      child: Container(
        width: 193.52,
        height: 95.50,
        padding: const EdgeInsets.all(12.61),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15.14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title + subtitle ──────────────────────────────────
            SizedBox(
              width: 168.29,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${items.length} items available',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── Divider ───────────────────────────────────────────
            Container(
              width: 166.51,
              height: 0.60,
              color: dividerColor.withOpacity(0.5),
            ),

            const SizedBox(height: 7),

            // ── Tap to view button ────────────────────────────────
            GestureDetector(
              onTap: () => _showMenuModal(context, title, items, room),
              child: Container(
                width: 168.29,
                height: 21.04,
                padding: const EdgeInsets.symmetric(horizontal: 5.01),
                decoration: BoxDecoration(
                  color: tapBgColor,
                  borderRadius: BorderRadius.circular(5.01),
                  border: isDark ? null : Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tap to view menu',
                      style: TextStyle(
                        color: tapTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Icon(
                      Icons.arrow_circle_right,
                      color: tapTextColor,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Show Modal ────────────────────────────────────────────────────────────────
void _showMenuModal(BuildContext context, String title, List items, Room room) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MenuBottomSheet(title: title, items: items),
  );

  if (result != null && context.mounted) {
    await room.sendTextEvent(result);
  }
}

// ── Bottom Sheet ──────────────────────────────────────────────────────────────
class _MenuBottomSheet extends StatefulWidget {
  final String title;
  final List items;

  const _MenuBottomSheet({required this.title, required this.items});

  @override
  State<_MenuBottomSheet> createState() => _MenuBottomSheetState();
}

class _MenuBottomSheetState extends State<_MenuBottomSheet> {
  // tracks quantity of each item by index
  final Map<int, int> _quantities = {};

  int get _totalItems => _quantities.values.fold(0, (a, b) => a + b);

  int _totalPrice() {
    int total = 0;
    for (final entry in _quantities.entries) {
      final item = widget.items[entry.key];
      final price = int.tryParse((item['price'] ?? '0').toString()) ?? 0;
      total += price * entry.value;
    }
    return total;
  }

  String _buildOrderMessage() {
    final List<String> orderLines = [];
    for (final entry in _quantities.entries) {
      if (entry.value > 0) {
        final item = widget.items[entry.key];
        final name = (item['name'] ?? '').toString();
        orderLines.add('$name x${entry.value}');
      }
    }
    return 'I want to order: ${orderLines.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final primaryText = isDark ? const Color(0xFF272727) : Colors.white;
    final secondaryText = const Color(0xFF8E8E93);
    final dividerColor = isDark ? const Color(0xFFD9D9D9) : const Color(0xFF3A3A3C);
    final numberBoxColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFD9D9D9);
    final plusBgColor = const Color(0xFF282828);
    final orderBarBg = isDark ? const Color(0xFF111111) : Colors.white;
    final orderBarText = isDark ? Colors.white : const Color(0xFF111111);
    final orderBtnBg = isDark ? Colors.white : const Color(0xFF111111);
    final orderBtnText = isDark ? const Color(0xFF111111) : Colors.white;
    final dragColor = isDark ? const Color(0xFFD9D9D9) : const Color(0xFFD9D9D9);

    return Container(
      width: 388.39,
      constraints: const BoxConstraints(maxHeight: 484.42),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28.43),
        ),
      ),
      padding: const EdgeInsets.all(21.87),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ───────────────────────────────────────────────────
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

          // ── Header ────────────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    widget.title,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF272727) : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -0.3,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  '${widget.items.length} items available',
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

          // ── Divider ───────────────────────────────────────────────────────
          Container(
            width: 338.99,
            height: 0.28,
            color: dividerColor,
          ),

          const SizedBox(height: 9.84),

          // ── Menu items list ───────────────────────────────────────────────
          SizedBox(
            width: 338.99,
            height: 280,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => Column(
                children: [
                  const SizedBox(height: 9.84),
                  Container(height: 0.28, color: dividerColor),
                  const SizedBox(height: 9.84),
                ],
              ),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final name = (item['name'] ?? '').toString();
                final price = (item['price'] ?? '').toString();
                final qty = _quantities[index] ?? 0;

                return SizedBox(
                  height: 36.09,
                  child: Row(
                    children: [
                      // ── Number box ──────────────────────────────────────
                      Container(
                        width: 26.31,
                        height: 26.31,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFFD9D9D9) : numberBoxColor,
                          borderRadius: BorderRadius.circular(4.38),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFFA7ABAE)
                                  : primaryText,
                              fontSize: 12.64,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Poppins',
                              letterSpacing: -0.139,
                              height: 10.78 / 12.64,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10.94),

                    
                      // ── Item name ───────────────────────────────────────
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF272727) : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          // ── Price ───────────────────────────────────────────
                          Text(
                            price,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF272727) : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                      const SizedBox(width: 11.33),

                      // ── Plus / Minus + Count ────────────────────────────
                      if (qty == 0)
                        GestureDetector(
                          onTap: () => setState(() => _quantities[index] = 1),
                          child: Container(
                            width: 26.25,
                            height: 26.25,
                            decoration: BoxDecoration(
                              color: plusBgColor,
                              borderRadius: BorderRadius.circular(4.53),
                              border: Border.all(
                                color: dividerColor,
                                width: 0.22,
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            // ── Minus ─────────────────────────────────────
                            GestureDetector(
                              onTap: () => setState(() {
                                if (_quantities[index]! > 1) {
                                  _quantities[index] = _quantities[index]! - 1;
                                } else {
                                  _quantities.remove(index);
                                }
                              }),
                              child: Container(
                                width: 26.25,
                                height: 26.25,
                                decoration: BoxDecoration(
                                  color: plusBgColor,
                                  borderRadius: BorderRadius.circular(4.53),
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // ── Count ─────────────────────────────────────
                            Text(
                              '$qty',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // ── Plus ──────────────────────────────────────
                            GestureDetector(
                              onTap: () => setState(
                                () => _quantities[index] =
                                    (_quantities[index] ?? 0) + 1,
                              ),
                              child: Container(
                                width: 26.25,
                                height: 26.25,
                                decoration: BoxDecoration(
                                  color: plusBgColor,
                                  borderRadius: BorderRadius.circular(4.53),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 14,
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

          const SizedBox(height: 9.66),

          // ── Order Now bar ─────────────────────────────────────────────────
          if (_totalItems > 0)
            Container(
              width: 344.65,
              height: 56.37,
              padding: const EdgeInsets.all(10.94),
              decoration: BoxDecoration(
                color: orderBarBg,
                borderRadius: BorderRadius.circular(8.75),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Total info ────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: orderBarText.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_totalItems item${_totalItems > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: orderBarText,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          'Total Rs ${_totalPrice()}',
                          style: TextStyle(
                            color: orderBarText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Order Now button ──────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      final msg = _buildOrderMessage();
                      Navigator.of(context).pop(msg);
                    },
                    child: Container(
                      width: 87.66,
                      height: 31.66,
                      decoration: BoxDecoration(
                        color: orderBtnBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          'Order Now',
                          style: TextStyle(
                            color: orderBtnText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}