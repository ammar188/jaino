// dsl_room_extension.dart
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

extension DSLRoomExtension on Room {
  static const _quickActionsType = 'com.jaino.dsl.quick_actions';

  Widget? buildQuickActions() {
    final state = getState(_quickActionsType);
    if (state == null) return null;

    final actions = state.content['actions'];
    if (actions is! List) return null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: actions.map<Widget>((action) {
          final label = action['label'] as String? ?? '';
          final icon = action['icon'] as String?;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: icon != null
                  ? Image.network(icon, width: 18, height: 18)
                  : null,
              label: Text(label),
              onPressed: () {},
            ),
          );
        }).toList(),
      ),
    );
  }
}