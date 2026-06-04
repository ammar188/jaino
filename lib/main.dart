import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/client_manager.dart';
import 'package:fluffychat/utils/notification_background_handler.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_vodozemac/flutter_vodozemac.dart' as vod;
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/universal_html.dart' as web;

import 'config/setting_keys.dart';
import 'dsl/handlers/appointment_handler.dart';
import 'dsl/handlers/menu_handler.dart';
import 'dsl/handlers/payment_dsl_handler.dart';
import 'dsl/models/dsl_registry.dart';
import 'utils/background_push.dart';
import 'widgets/fluffy_chat_app.dart';

ReceivePort? mainIsolateReceivePort;

bool _vodozemacInitialized = false;

void main() async {
  if (PlatformInfos.isAndroid) {
    final port = mainIsolateReceivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping(AppConfig.mainIsolatePortName);
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      AppConfig.mainIsolatePortName,
    );
    await waitForPushIsolateDone();
  }

  // Sanitize hash for OIDC:
  if (kIsWeb) {
    final hash = web.window.location.hash;
    if (hash.isNotEmpty && !hash.startsWith('/')) {
      web.window.location.hash = hash.replaceFirst('#', '#?');
    }
  }

  // Our background push shared isolate accesses flutter-internal things very early in the startup proccess
  // To make sure that the parts of flutter needed are started up already, we need to ensure that the
  // widget bindings are initialized already.
  WidgetsFlutterBinding.ensureInitialized();

  final store = await AppSettings.init();
  Logs().i('Welcome to ${AppSettings.applicationName.value} <3');

  if (!_vodozemacInitialized) {
    await vod.init(wasmPath: './assets/assets/vodozemac/');
    _vodozemacInitialized = true;
  }

  Logs().nativeColors = !PlatformInfos.isIOS;
  final clients = await ClientManager.getClients(store: store);

  late final SupabaseClient supabase;

  Future<void> initSupabase() async {
    final result = await Supabase.initialize(
      url: AppSettings.supabaseUrl.value,
      anonKey: AppSettings.supabaseAnonKey.value,
    );

    supabase = result.client;
  }
  await initSupabase();

  const String _edgeFunctionUrl =
      'https://loektgljcwcpgnezlqon.supabase.co/functions/v1/matrix_oidc/token';

  /// Step 1: Exchange Matrix token for a Supabase-compatible JWT
  Future<String> exchangeMatrixToken(String matrixAccessToken) async {
    print('[EdgeCall] Exchanging Matrix token... $matrixAccessToken');

    final response = await http.post(
      Uri.parse(_edgeFunctionUrl),
      headers: {
        'Authorization': 'Bearer $matrixAccessToken',
        'Content-Type': 'application/json',
      },
    );

    print('[EdgeCall] Status: ${response.statusCode}');
    print('[EdgeCall] Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('[EdgeCall] Failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final idToken = data['id_token'] as String?;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('[EdgeCall] Missing id_token in response');
    }

    return idToken;
  }

  /// Step 2: Sign into Supabase using the JWT from the edge function
  Future<void> signInToSupabase(String idToken) async {
    print('[MatrixAuth] Signing into Supabase... $idToken');

    final res = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider('custom:matrix'),
      // name you registered in Supabase
      idToken: idToken,
    );

    if (res.session == null) {
      throw Exception('[MatrixAuth] Supabase session is null after signIn');
    }

    print('[MatrixAuth] Signed in as: ${res.session!.user.id}');
  }

  bool _isLoggingIn = false;

  Future<void> handleMatrixLogin(String matrixUserId) async {
    if (_isLoggingIn) {
      print('[MatrixAuth] Already in progress, skipping.');
      return;
    }

    _isLoggingIn = true;

    try {
      print('[MatrixAuth] Handling login for: $matrixUserId');

      // Skip if already have a valid Supabase session
      final session = supabase.auth.currentSession;
      if (session != null && !session.isExpired) {
        print('[MatrixAuth] Session already valid, skipping.');
        return;
      }

      final matrixToken = clients.first.accessToken;
      if (matrixToken == null || matrixToken.isEmpty) {
        throw Exception('[MatrixAuth] Matrix access token is null or empty');
      }

      // Exchange Matrix token → JWT via edge function
      final idToken = await exchangeMatrixToken(matrixToken);

      // Sign into Supabase with the JWT
      await signInToSupabase(idToken);

      print('[MatrixAuth] Login complete ✔');
    } catch (e, stack) {
      print('[MatrixAuth][ERROR] $e');
      print(stack);
    } finally {
      _isLoggingIn = false;
    }
  }

  Future<void> handleMatrixLogout() async {
    try {
      print('[MatrixAuth] Handling logout...');

      final session = supabase.auth.currentSession;

      if (session == null) {
        print('[MatrixAuth] No Supabase session, skipping.');
        return;
      }

      await supabase.auth.signOut();

      print('[MatrixAuth] Supabase logout complete ✔');
    } catch (e, stack) {
      print('[MatrixAuth][LOGOUT ERROR] $e');
      print(stack);
    }
  }

  void initMatrixAuth() {
    final client = clients.first;
    print('[MatrixAuth] Initializing...');

    // Handle already-logged-in Matrix user on startup
    if (client.userID != null) {
      print('[MatrixAuth] Existing Matrix user: ${client.userID}');
      handleMatrixLogin(client.userID!);
    }

    // Listen for future login state changes
    client.onLoginStateChanged.stream.distinct().listen((state) async {
      print('[MatrixAuth] State changed: $state');
      if (state == LoginState.loggedIn && client.userID != null) {
        await handleMatrixLogin(client.userID!);
      }

      if (state == LoginState.loggedOut) {
        await handleMatrixLogout();
      }
    });
  }

  initMatrixAuth();
  // If the app starts in detached mode, we assume that it is in
  // background fetch mode for processing push notifications. This is
  // currently only supported on Android.
  if (PlatformInfos.isAndroid &&
      AppLifecycleState.detached == WidgetsBinding.instance.lifecycleState) {
    // Do not send online presences when app is in background fetch mode.
    for (final client in clients) {
      client.backgroundSync = false;
      client.syncPresence = PresenceType.offline;
    }

    // In the background fetch mode we do not want to waste ressources with
    // starting the Flutter engine but process incoming push notifications.
    BackgroundPush.clientOnly(clients.first);
    // To start the flutter engine afterwards we add an custom observer.
    WidgetsBinding.instance.addObserver(AppStarter(clients, store));
    Logs().i(
      '${AppSettings.applicationName.value} started in background-fetch mode. No GUI will be created unless the app is no longer detached.',
    );
    return;
  }

  // Started in foreground mode.
  Logs().i(
    '${AppSettings.applicationName.value} started in foreground mode. Rendering GUI...',
  );
  setupDSL();
  await startGui(clients, store);
}

// todo(ammar): this is a bit hacky, we should find a better way to register the handlers before the GUI starts.
void setupDSL() {
  DSLRegistry.instance.register(MenuDSLHandler());
  DSLRegistry.instance.register(PaymentDSLHandler());
  DSLRegistry.instance.register(AppointmentDSLHandler());
}

/// Fetch the pincode for the applock and start the flutter engine.
Future<void> startGui(List<Client> clients, SharedPreferences store) async {
  // Fetch the pin for the applock if existing for mobile applications.
  String? pin;
  if (PlatformInfos.isMobile) {
    try {
      pin = await const FlutterSecureStorage().read(
        key: 'chat.fluffy.app_lock',
      );
    } catch (e, s) {
      Logs().d('Unable to read PIN from Secure storage', e, s);
    }
  }

  // Preload first client
  final firstClient = clients.firstOrNull;
  await firstClient?.roomsLoading;
  await firstClient?.accountDataLoading;

  runApp(FluffyChatApp(clients: clients, pincode: pin, store: store));
}

/// Watches the lifecycle changes to start the application when it
/// is no longer detached.
class AppStarter with WidgetsBindingObserver {
  final List<Client> clients;
  final SharedPreferences store;
  bool guiStarted = false;

  AppStarter(this.clients, this.store);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (guiStarted) return;
    if (state == AppLifecycleState.detached) return;

    Logs().i(
      '${AppSettings.applicationName.value} switches from the detached background-fetch mode to ${state.name} mode. Rendering GUI...',
    );
    // Switching to foreground mode needs to reenable send online sync presence.
    for (final client in clients) {
      client.backgroundSync = true;
      client.syncPresence = PresenceType.online;
    }
    startGui(clients, store);
    // We must make sure that the GUI is only started once.
    guiStarted = true;
  }
}
