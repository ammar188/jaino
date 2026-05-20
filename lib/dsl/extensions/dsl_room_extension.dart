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
  padding: const EdgeInsets.fromLTRB(0,0,0,6),
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: actions.map<Widget>((action) {
        final label = action['label'] as String? ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SizedBox(
            width: MediaQuery.of(context).size.width / 3.9,
            child: ElevatedButton(
              onPressed: () => onActionTap(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }).toList(),
    ),
  ),
);
}
}