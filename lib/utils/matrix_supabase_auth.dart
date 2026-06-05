import 'package:matrix/matrix.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles authentication synchronization between Matrix and Supabase.
class MatrixSupabaseAuthService {
  static const String _edgeFunctionName = 'matrix_oidc';

  final List<Client> _matrixClients;
  final SupabaseClient _supabase;

  MatrixSupabaseAuthService({
    required List<Client> matrixClients,
    required SupabaseClient supabase,
  })  : _matrixClients = matrixClients,
        _supabase = supabase;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Call once on app startup. Logs into Supabase if Matrix user is
  /// already logged in, and listens for future logouts.
  Future<void> init() async {

    if (_matrixClients.isEmpty) {
      return;
    }

    final client = _matrixClients.first;

    // If already logged into Matrix on startup, sync Supabase
    if (client.userID != null) {
      await _loginToSupabase(client);
    }

    // Watch for logouts only
    client.onLoginStateChanged.stream.listen((state) async {
      if (state == LoginState.loggedOut) {
        await _logoutFromSupabase();
      }
    });
  }

  /// Call this after a successful Matrix login (e.g. from login.dart).
  Future<void> onMatrixLogin(Client client) async {
    await _loginToSupabase(client);
  }

  /// Returns true if there is a valid Supabase session.
  bool get isAuthenticated {
    final session = _supabase.auth.currentSession;
    return session != null && !session.isExpired;
  }

  /// Returns the current Supabase user, or null if not authenticated.
  User? get currentUser => _supabase.auth.currentUser;

  /// Returns the Matrix user ID from user_metadata, or null.
  String? get matrixUserId =>
      _supabase.auth.currentUser?.userMetadata?['sub'] as String?;

  // ─── Private ──────────────────────────────────────────────────────────────

  Future<void> _loginToSupabase(Client client) async {
    try {
      if (isAuthenticated) {
        Logs().i('[MatrixAuth] Supabase session already valid, skipping.');
        return;
      }

      final matrixToken = client.accessToken;
      if (matrixToken == null || matrixToken.isEmpty) {
        throw Exception('Matrix access token is null or empty');
      }

      final idToken = await _exchangeMatrixToken(matrixToken);
      await _signInToSupabase(idToken);

      Logs().i('[MatrixAuth] Login complete ✔ user: ${currentUser?.id}');
    } catch (e, stack) {
      Logs().e('[MatrixAuth] Login failed', e, stack);
    }
  }

  Future<void> _logoutFromSupabase() async {
    try {
      if (_supabase.auth.currentSession == null) return;
      await _supabase.auth.signOut();
    } catch (e, stack) {
      Logs().e('[MatrixAuth] Logout failed', e, stack);
    }
  }

  Future<String> _exchangeMatrixToken(String matrixAccessToken) async {

    final response = await _supabase.functions.invoke(
      '$_edgeFunctionName/token',
      headers: {'Authorization': 'Bearer $matrixAccessToken'},
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null) throw Exception('Edge function returned null');
    if (data['error'] != null) throw Exception('Edge function error: ${data['error']}');

    final idToken = data['id_token'] as String?;
    if (idToken == null || idToken.isEmpty) throw Exception('Missing id_token');

    return idToken;
  }

  Future<void> _signInToSupabase(String idToken) async {

    final res = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider('custom:matrix'),
      idToken: idToken,
    );

    if (res.session == null) {
      throw Exception('Supabase session is null after signInWithIdToken');
    }
  }
}