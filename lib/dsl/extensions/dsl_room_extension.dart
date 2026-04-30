// dsl_room_extension.dart
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

extension DSLRoomExtension on Room {
  static const _quickActionsType = 'com.jaino.dsl.quick_actions';

  Widget? buildQuickActions(
    BuildContext context, {
    required void Function(String label) onActionTap,
  }) {
    final state = getState(_quickActionsType);
    if (state == null) return null;

    final actions = state.content['actions'];
    if (actions is! List) return null;

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Row(
        children: actions.map<Widget>((action) {
          final label = action['label'] as String? ?? '';
          final icon  = action['icon']  as String? ?? '';

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
  backgroundColor: Colors.white,
  foregroundColor: Colors.black,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  padding: const EdgeInsets.symmetric(vertical: 10),
),
                onPressed: () => onActionTap(label),
                child: Text(label),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}