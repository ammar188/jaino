import 'package:fluffychat/utils/loyalty_service.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'loyalty_page.dart';

class LoyaltyPageView extends StatelessWidget {
  final LoyaltyPageController controller;

  const LoyaltyPageView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: PreferredSize(
        preferredSize: const Size(390, 110),
        child: Container(
          width: 390,
          height: 110,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.only(
            left: 29,
            right: 29,
            bottom: 10,
          ),
          child: SafeArea(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF70737D),
                    size: 16,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Loyalty Points',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
      body: MaxWidthBody(
        withScrolling: false,
        child: FutureBuilder<LoyaltyPageData>(
          future: controller.dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator.adaptive(),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load loyalty data',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: controller.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            return RefreshIndicator.adaptive(
              onRefresh: () async => controller.refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PointsCard(points: data.points),
                  if (data.referralCode != null) ...[
                    const SizedBox(height: 16),
                    _ReferralBanner(code: data.referralCode!),
                  ],
                  const SizedBox(height: 24),
                  if (data.transactions.isEmpty)
                    const _EmptyHistory()
                  else ...[
                    const Text(
                      'History',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...data.transactions.map(
                      (t) => _TransactionTile(transaction: t),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  final int points;
  const _PointsCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: const Color(0xFF7150DB),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.star_rounded,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              '$points',
              style: theme.textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'loyalty points',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No activity yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final LoyaltyTransaction transaction;
  const _TransactionTile({required this.transaction});

  static const _labels = {
    'signup_bonus': 'Welcome bonus',
    'referral_given': 'Referral reward — you invited someone',
    'referral_received': 'Referral reward — you were invited',
  };

  static const _icons = {
    'signup_bonus': Icons.celebration_outlined,
    'referral_given': Icons.person_add_outlined,
    'referral_received': Icons.card_giftcard_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _labels[transaction.reason] ?? transaction.reason;
    final icon = _icons[transaction.reason] ?? Icons.star_outline;
    final dateStr = DateFormat('d MMM yyyy').format(transaction.createdAt.toLocal());

    return Container(
      width: 331,
      height: 100,
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEDE8FB),
            child: Icon(icon, color: const Color(0xFF7150DB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${transaction.amount} pts',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7150DB),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralBanner extends StatelessWidget {
  final String code;
  const _ReferralBanner({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invite friends to Jaeno',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Share your code — you both earn 100 points when they sign up.',
            style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE8FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: Color(0xFF7150DB),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Copy code',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Referral code copied!')),
                  );
                },
                icon: const Icon(Icons.copy_outlined, color: Color(0xFF7150DB)),
              ),
              IconButton(
                tooltip: 'Share',
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Join me on Jaeno! Use my referral code $code when signing up and we both get 100 bonus points.',
                  ),
                ),
                icon: const Icon(Icons.share_outlined, color: Color(0xFF7150DB)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
