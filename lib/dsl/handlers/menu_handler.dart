import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../models/dsl_handler.dart';
import '../models/dsl_message.dart';
import '../models/dsl_render_result.dart';
import 'dart:ui';
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
    final bottomBg = const Color(0xFFF4F6FB);
    final textColor = const Color(0xFF111111);

    return GestureDetector(
      onTap: () => _showMenuModal(context, title, items, room),
      child: Container(
        width: 193.52,
        height: 136.77,
        decoration: BoxDecoration(
          color: bottomBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top image area ────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                width: 193.52,
                height: 90.5,
                color: const Color(0xFFE8E8E8),
                child: Image.asset(
                  'assets/menu_banner.png',
                  width: 193.52,
                  height: 90.5,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 193.52,
                    height: 90.5,
                    color: const Color(0xFFE0E0E0),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Color(0xFFAAAAAA),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom tap area ───────────────────────────────────────────
           Container(
  width: 193.52,
  height: 46.27,
  padding: const EdgeInsets.all(12.61),
  decoration: const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(12),
    ),
  ),
  child: Center(
    child: Container(
      width: 173.04,
      height: 21.04,
      padding: const EdgeInsets.all(5.01),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(5.01),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tap to view  menu',
            style: TextStyle(
              color: textColor,
              fontSize: 8,
              fontWeight: FontWeight.w400,
            ),
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
    // ── Fixed color tokens — always black modal, white cards ──────────────────
    const Color modalBg       = Color(0xFF111111);
    const Color cardBg        = Colors.white;
    const Color primaryText   = Color(0xFF1F1F1F);
    const Color secondaryText = Color(0xFF8E8E93);
    const Color dividerColor  = Color(0xFFFFFFFF);
    const Color numberBoxBg   = Color(0xFFD9D9D9);
    const Color numberBoxText = Color(0xFFA7ABAE);
    const Color plusBg        = Color(0xFF1C1C1E);
    const Color orderBarBg    = Colors.white;
    const Color orderBarText  = Color(0xFF111111);
    const Color orderBtnBg    = Color(0xFF111111);
    const Color orderBtnText  = Colors.white;
    const Color dragColor     = Color(0xFF3A3A3A);

    return BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
  child: Container(
    constraints: const BoxConstraints(maxHeight: 577.91),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF7150DB).withOpacity(0.81),
          Colors.white.withOpacity(0.81),
        ],
      ),
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(28.5),
      ),
    ),
      padding: const EdgeInsets.all(21.92),
      child: Column(
        mainAxisSize: MainAxisSize.max,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 22,
                    letterSpacing: -1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.items.length} items available',
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),


Container(
  width: 330.81,
  height: 0,
  decoration: BoxDecoration(
    border: Border(
      bottom: BorderSide(
        color: const Color(0xFFFFFFFF),
        width: 0.28,
      ),
    ),
  ),
),

const SizedBox(height: 9.84),


          // ── Menu items list ───────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9.68),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final name  = (item['name']  ?? '').toString();
                final price = (item['price'] ?? '').toString();
                final image = (item['image'] ?? '').toString();
                final qty   = _quantities[index] ?? 0;

                return 
                Container(
                  width: double.infinity,
                  height: 64,
                  padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12,  right: 12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // ── Thumbnail / number box ──────────────────────────
                      Container(
  width: 40,
  height: 40,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(7),
    border: Border.all(
      color: const Color(0xFFD9D9D9),
      width: 0.8,
    ),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(7),
    child: image.isNotEmpty
        ? Image.network(
            image,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _numberBox(index, numberBoxBg, numberBoxText),
          )
        : _numberBox(index, numberBoxBg, numberBoxText),
  ),
),

                      const SizedBox(width: 9.87),

                      // ── Name + price ────────────────────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: primaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              price,
                              style: const TextStyle(
                                color: primaryText,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Plus / Minus controls ───────────────────────────
                      if (qty == 0)
                        GestureDetector(
                          onTap: () => setState(() => _quantities[index] = 1),
                          child: Container(
                            width: 17.04,
                            height: 17.04,
                            padding: const EdgeInsets.all(0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7150DB),
                              borderRadius: BorderRadius.circular(4.54),
                              border: Border.all(
                                color: dividerColor,
                                width: 0.22,
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 11,
                            ),
                          ),
                        )
                      else
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Minus
      GestureDetector(
        onTap: () => setState(() {
          if (_quantities[index]! > 1) {
            _quantities[index] = _quantities[index]! - 1;
          } else {
            _quantities.remove(index);
          }
        }),
        child: Container(
          width: 17.04,
          height: 17.04,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(4.54),
            border: Border.all(
              color: const Color(0xFFC9C9C9),
              width: 0.22,
            ),
          ),
          child: const Icon(
            Icons.remove,
             color: Color(0xFFA7ABAE),
            size: 13,
          ),
        ),
      ),

      const SizedBox(width: 4),

      // Count box
      Container(
        width: 32.72,
        height: 17.04,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.54),
          border: Border.all(
            color: const Color(0xFFC9C9C9),
            width: 0.22,
          ),
        ),
        child: Center(
          child: Text(
            '$qty',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),

      const SizedBox(width: 4),

      // Plus
      GestureDetector(
        onTap: () => setState(
          () => _quantities[index] = (_quantities[index] ?? 0) + 1,
        ),
        child: Container(
          width: 17.04,
          height: 17.04,
          decoration: BoxDecoration(
            color: const Color(0xFF7150DB),
            borderRadius: BorderRadius.circular(4.54),
            border: Border.all(
              color: const Color(0xFFC9C9C9),
              width: 0.22,
            ),
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 13,
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
              width: double.infinity,
              height: 66,
              padding: const EdgeInsets.all(10.96),
              decoration: BoxDecoration(
                color: orderBarBg,
                borderRadius: BorderRadius.circular(8.77),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Total info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: orderBarText.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_totalItems item${_totalItems > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: orderBarText,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Rs ${_totalPrice()}',
                          style: const TextStyle(
                            color: orderBarText,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Order Now button
                  GestureDetector(
                    onTap: () {
                      final msg = _buildOrderMessage();
                      Navigator.of(context).pop(msg);
                    },
                    child: Container(
                      width: 87.72,
                      height: 31.72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7150DB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                          width: 0.22,
                        ),
                      ),
                      child: const Center(
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
  ),
    );
  }

  Widget _numberBox(int index, Color bg, Color textColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4.38),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: textColor,
            fontSize: 12.64,
            fontWeight: FontWeight.w400,
            fontFamily: 'Poppins',
            letterSpacing: -0.139,
            height: 10.78 / 12.64,
          ),
        ),
      ),
    );
  }
}



