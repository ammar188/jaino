import 'package:fluffychat/utils/loyalty_service.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'loyalty_page.dart';

class LoyaltyPageView extends StatelessWidget {
  final LoyaltyPageController controller;

  const LoyaltyPageView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Center(child: BackButton()),
        title: const Text('Loyalty Points'),
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
                  const SizedBox(height: 24),
                  if (data.transactions.isEmpty)
                    const _EmptyHistory()
                  else ...[
                    Text(
                      'History',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
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
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.star_rounded,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              '$points',
              style: theme.textTheme.displayMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'loyalty points',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
      ),
      title: Text(label),
      subtitle: Text(
        dateStr,
        style: TextStyle(color: theme.colorScheme.outline),
      ),
      trailing: Text(
        '+${transaction.amount} pts',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
