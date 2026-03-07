import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../services/firebase_service.dart';
import '../services/sync_service.dart';
import 'task_provider.dart';

/// Auth state exposed via Riverpod.
enum AuthStatus { unknown, signedOut, signedIn }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhotoUrl;
  final DateTime? lastSyncTime;
  final bool isSyncing;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhotoUrl,
    this.lastSyncTime,
    this.isSyncing = false,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhotoUrl,
    DateTime? lastSyncTime,
    bool? isSyncing,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
    );
  }

  bool get isSignedIn => status == AuthStatus.signedIn;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseService _firebase;
  SyncService? _syncService;
  StreamSubscription<String?>? _authSub;

  /// Exposed so other providers can push changes when user is signed in.
  SyncService? get syncService => _syncService;

  AuthNotifier({FirebaseService? firebaseService})
    : _firebase = firebaseService ?? FirebaseService.instance,
      super(const AuthState()) {
    _init();
  }

  void _init() {
    // Listen to Firebase auth state changes
    _authSub = _firebase.authStateChanges.listen((uid) {
      if (uid != null) {
        _onSignedIn(uid);
      } else {
        _onSignedOut();
      }
    });

    // Check current auth state
    if (_firebase.isSignedIn) {
      _onSignedIn(_firebase.currentUserId!);
    } else {
      state = const AuthState(status: AuthStatus.signedOut);
    }
  }

  void _onSignedIn(String uid) async {
    // Clear local data if a different account was previously signed in
    const lastUidKey = 'last_signed_in_uid';
    final prefs = await SharedPreferences.getInstance();
    final lastUid = prefs.getString(lastUidKey);
    if (lastUid != null && lastUid != uid) {
      debugPrint(
        '🔐 [Auth] Account switch detected ($lastUid → $uid), clearing local data',
      );
      await DatabaseHelper.instance.clearAllData();
    }
    await prefs.setString(lastUidKey, uid);

    _syncService = SyncService(uid: uid);

    // Set up the remote change callback to reload tasks
    _syncService!.onRemoteTaskChange = () {
      debugPrint('🔐 [Auth] Remote task change detected');
    };

    // Update lastSyncTime in state whenever sync completes
    _syncService!.onSyncTimeUpdated = () {
      state = state.copyWith(lastSyncTime: _syncService!.lastSyncTime);
    };

    // Surface sync errors to UI
    _syncService!.onSyncError = (String error) {
      debugPrint('🔐 [Auth] Sync error: $error');
      state = state.copyWith(errorMessage: error);
    };

    state = AuthState(
      status: AuthStatus.signedIn,
      userId: uid,
      userName: _firebase.currentUserName,
      userEmail: _firebase.currentUserEmail,
      userPhotoUrl: _firebase.currentUserPhotoUrl,
      isSyncing: true,
    );
    debugPrint('🔐 [Auth] Signed in as $uid');

    // Run initial sync, then start listeners, then cleanup old deletes
    _syncService!
        .initialSync()
        .then((_) {
          state = state.copyWith(
            isSyncing: false,
            lastSyncTime: _syncService!.lastSyncTime,
          );
          // Periodically clean up soft-deleted tasks older than 30 days
          _syncService!.cleanupSyncedDeletes();
        })
        .catchError((Object e) {
          debugPrint('❌ [Auth] Initial sync error: $e');
          state = state.copyWith(isSyncing: false, errorMessage: e.toString());
        });
  }

  void _onSignedOut() {
    _syncService?.stopListeners();
    _syncService = null;
    state = const AuthState(status: AuthStatus.signedOut);
    debugPrint('🔐 [Auth] Signed out');
  }

  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(errorMessage: null);
      await _firebase.signInWithGoogle();
    } catch (e) {
      debugPrint('❌ [Auth] Google sign-in failed: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> signInWithApple() async {
    try {
      state = state.copyWith(errorMessage: null);
      await _firebase.signInWithApple();
    } catch (e) {
      debugPrint('❌ [Auth] Apple sign-in failed: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    _syncService?.stopListeners();
    _syncService = null;
    try {
      await _firebase.signOut();
    } catch (e) {
      debugPrint('❌ [Auth] Sign-out error (continuing): $e');
    }
    state = const AuthState(status: AuthStatus.signedOut);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _syncService?.stopListeners();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier();

  // Wire SyncService into TaskProvider when auth state changes
  notifier.addListener((authState) {
    final tasks = ref.read(taskProvider);
    if (authState.isSignedIn) {
      tasks.syncService = notifier.syncService;
      // Reload tasks after remote changes applied by SyncService
      notifier.syncService?.onRemoteTaskChange = () {
        tasks.reloadTasks();
      };
    } else {
      tasks.syncService = null;
    }
  });

  return notifier;
});
