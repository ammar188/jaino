import 'dart:math';

import 'package:matrix/matrix.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoyaltyTransaction {
  final String id;
  final int amount;
  final String reason;
  final DateTime createdAt;

  const LoyaltyTransaction({
    required this.id,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) =>
      LoyaltyTransaction(
        id: json['id'] as String,
        amount: json['amount'] as int,
        reason: json['reason'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class LoyaltyService {
  static const int signupPoints = 50;
  static const int referralPoints = 100;

  final SupabaseClient _supabase;

  LoyaltyService({required SupabaseClient supabase}) : _supabase = supabase;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Call once after a new user's Supabase session is established.
  /// Awards signup points and applies [referralCode] if provided.
  Future<void> onNewUserRegistered(
    String userId, {
    String? referralCode,
  }) async {
    try {
      await _awardPoints(userId, signupPoints, 'signup_bonus');
      await _ensureReferralCode(userId);
      final code = referralCode?.trim().toUpperCase();
      if (code != null && code.isNotEmpty) {
        await _applyReferralCode(code, userId);
      }
    } catch (e, stack) {
      Logs().e('[Loyalty] onNewUserRegistered failed', e, stack);
    }
  }

  /// Returns the user's current point balance, or 0 on error.
  Future<int> getPoints(String userId) async {
    try {
      final row = await _supabase
          .from('user_points')
          .select('points')
          .eq('user_id', userId)
          .maybeSingle();
      return (row?['points'] as int?) ?? 0;
    } catch (e, stack) {
      Logs().e('[Loyalty] getPoints failed', e, stack);
      return 0;
    }
  }

  /// Returns the referral code for [userId], creating one if needed.
  Future<String?> getReferralCode(String userId) async {
    try {
      return await _ensureReferralCode(userId);
    } catch (e, stack) {
      Logs().e('[Loyalty] getReferralCode failed', e, stack);
      return null;
    }
  }

  /// Returns the transaction history for [userId], newest first.
  Future<List<LoyaltyTransaction>> getTransactions(String userId) async {
    try {
      final rows = await _supabase
          .from('loyalty_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((r) => LoyaltyTransaction.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      Logs().e('[Loyalty] getTransactions failed', e, stack);
      return [];
    }
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  /// Calls the award_loyalty_points Supabase function, which atomically
  /// updates user_points and appends a loyalty_transactions row.
  Future<void> _awardPoints(String userId, int amount, String reason) async {
    await _supabase.rpc(
      'award_loyalty_points',
      params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_reason': reason,
      },
    );
    Logs().i('[Loyalty] $reason awarded to $userId (+$amount)');
  }

  Future<String> _ensureReferralCode(String userId) async {
    final existing = await _supabase
        .from('referral_codes')
        .select('code')
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) return existing['code'] as String;

    final code = _generateCode();
    await _supabase.from('referral_codes').insert({
      'user_id': userId,
      'code': code,
    });
    Logs().i('[Loyalty] Referral code created for $userId: $code');
    return code;
  }

  Future<void> _applyReferralCode(String code, String newUserId) async {
    final referrerRow = await _supabase
        .from('referral_codes')
        .select('user_id')
        .eq('code', code)
        .maybeSingle();

    if (referrerRow == null) {
      Logs().w('[Loyalty] Referral code not found: $code');
      return;
    }

    final referrerId = referrerRow['user_id'] as String;

    if (referrerId == newUserId) {
      Logs().w('[Loyalty] User tried to use their own referral code');
      return;
    }

    // Guard against duplicate referrals (referred_id is PRIMARY KEY in the table).
    try {
      await _supabase.from('referral_uses').insert({
        'referrer_id': referrerId,
        'referred_id': newUserId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        Logs().w('[Loyalty] User $newUserId was already referred, skipping.');
        return;
      }
      rethrow;
    }

    await Future.wait([
      _awardPoints(referrerId, referralPoints, 'referral_given'),
      _awardPoints(newUserId, referralPoints, 'referral_received'),
    ]);

    Logs().i(
      '[Loyalty] Referral applied: $referrerId -> $newUserId (+$referralPoints each)',
    );
  }

  static String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
