import 'package:fluffychat/config/routes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../widgets/matrix.dart';

abstract class FluffyShare {
  static Future<void> share(
    String text,
    BuildContext context, {
    bool copyOnly = false,
  }) async {
    final l10n = L10n.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (PlatformInfos.isMobile && !copyOnly) {
      final box = context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!PlatformInfos.isMobile) {
      scaffoldMessenger.showSnackBar(
        SnackBar(showCloseIcon: true, content: Text(l10n.copiedToClipboard)),
      );
    }
    return;
  }

  static Future<void> shareInviteLink(BuildContext context) async {
    final l10n = L10n.of(context);
    final client = Matrix.of(context).client;
    final ownProfile = await client.fetchOwnProfile();
    if (!context.mounted) return;

    final userId =
        supabase.Supabase.instance.client.auth.currentUser?.id;
    final referralCode = userId != null
        ? await AppRoutes.loyalty.getReferralCode(userId)
        : null;

    final baseText = l10n.inviteText(
      ownProfile.displayName ?? client.userID!,
      'https://matrix.to/#/${client.userID}?client=im.fluffychat',
    );
    // todo(ammar): use l10n please
    final text = referralCode != null
        ? '$baseText\n\nUse referral code $referralCode when signing up and we both get 100 bonus points!'
        : baseText;

    if (!context.mounted) return;
    await FluffyShare.share(text, context);
  }
}
