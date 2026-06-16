import 'package:fluffychat/config/routes.dart';
import 'package:fluffychat/utils/loyalty_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'loyalty_page_view.dart';

class LoyaltyPageData {
  final int points;
  final List<LoyaltyTransaction> transactions;

  const LoyaltyPageData({required this.points, required this.transactions});
}

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  LoyaltyPageController createState() => LoyaltyPageController();
}

class LoyaltyPageController extends State<LoyaltyPage> {
  late Future<LoyaltyPageData> dataFuture;

  @override
  void initState() {
    super.initState();
    dataFuture = _load();
  }

  Future<LoyaltyPageData> _load() async {
    final userId =
        supabase.Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return const LoyaltyPageData(points: 0, transactions: []);
    }
    final results = await Future.wait([
      AppRoutes.loyalty.getPoints(userId),
      AppRoutes.loyalty.getTransactions(userId),
    ]);
    return LoyaltyPageData(
      points: results[0] as int,
      transactions: results[1] as List<LoyaltyTransaction>,
    );
  }

  void refresh() => setState(() {
        dataFuture = _load();
      });

  @override
  Widget build(BuildContext context) => LoyaltyPageView(this);
}
