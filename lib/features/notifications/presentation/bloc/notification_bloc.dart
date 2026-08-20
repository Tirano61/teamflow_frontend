import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../data/datasources/firebase_messaging_data_source.dart';
import '../../domain/repositories/notification_device_repository.dart';
import '../../domain/usecases/register_device.dart';
import '../../domain/usecases/unregister_device.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({
    required FirebaseMessagingDataSource messagingDataSource,
    required RegisterDevice registerDevice,
    required UnregisterDevice unregisterDevice,
  }) : _messagingDataSource = messagingDataSource,
       _registerDevice = registerDevice,
       _unregisterDevice = unregisterDevice,
       super(const NotificationState()) {
    on<InitializeNotificationsEvent>(_onInitializeNotifications);
    on<NotificationAuthStateChangedEvent>(_onAuthStateChanged);
    on<NotificationTokenRefreshedEvent>(_onTokenRefreshed);
    on<NotificationForegroundMessageReceivedEvent>(
      _onForegroundMessageReceived,
    );
    on<NotificationOpenedEvent>(_onNotificationOpened);
    on<NotificationNavigationHandledEvent>(_onNavigationHandled);
    on<NotificationActiveDiscussionChangedEvent>(_onActiveDiscussionChanged);
    on<NotificationAppLifecycleResumedEvent>(_onAppLifecycleResumed);
  }

  final FirebaseMessagingDataSource _messagingDataSource;
  final RegisterDevice _registerDevice;
  final UnregisterDevice _unregisterDevice;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<Map<String, String>>? _foregroundMessageSubscription;
  StreamSubscription<Map<String, String>>? _messageOpenedSubscription;

  Future<void> _onInitializeNotifications(
    InitializeNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.initialized) {
      return;
    }

    emit(
      state.copyWith(status: NotificationStatus.initializing, errorMessage: ''),
    );

    final pushSupported = _messagingDataSource.isSupported;
    if (!pushSupported) {
      emit(
        state.copyWith(
          status: NotificationStatus.ready,
          pushSupported: false,
          initialized: true,
          errorMessage: '',
        ),
      );
      return;
    }

    _tokenRefreshSubscription = _messagingDataSource.onTokenRefresh.listen((
      token,
    ) {
      add(NotificationTokenRefreshedEvent(token));
    });

    _foregroundMessageSubscription = _messagingDataSource.onMessage.listen((
      data,
    ) {
      final type = data['type']?.trim() ?? '';
      final discussionId = _readDiscussionId(data) ?? '-';

      if (kDebugMode) {
        debugPrint(
          '[FCM] onMessage received - ${_timestampNow()} - '
          'type=$type discussionId=$discussionId',
        );
      }

      add(NotificationForegroundMessageReceivedEvent(data));
    });

    _messageOpenedSubscription = _messagingDataSource.onMessageOpenedApp.listen(
      (data) {
        if (kDebugMode) {
          debugPrint('FCM onMessageOpenedApp received. data=$data');
        }

        add(NotificationOpenedEvent(data: data, source: 'onMessageOpenedApp'));
      },
    );

    try {
      final initialMessage = await _messagingDataSource.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          debugPrint('FCM getInitialMessage received. data=$initialMessage');
        }

        add(
          NotificationOpenedEvent(
            data: initialMessage,
            source: 'getInitialMessage',
          ),
        );
      }

      emit(
        state.copyWith(
          status: NotificationStatus.ready,
          pushSupported: true,
          initialized: true,
          errorMessage: '',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          pushSupported: true,
          initialized: true,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onAuthStateChanged(
    NotificationAuthStateChangedEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final wasAuthenticated = state.isAuthenticated;

    emit(
      state.copyWith(isAuthenticated: event.isAuthenticated, errorMessage: ''),
    );

    if (!state.pushSupported || !state.initialized) {
      return;
    }

    if (event.isAuthenticated) {
      await _ensurePermissionAndToken(emit);
      final token = state.currentFcmToken?.trim();
      if (token != null && token.isNotEmpty) {
        await _registerTokenIfNeeded(token, emit);
      }

      final pendingDiscussionId = state.pendingDiscussionId?.trim();
      if (pendingDiscussionId != null && pendingDiscussionId.isNotEmpty) {
        emit(
          state.copyWith(
            openDiscussionId: pendingDiscussionId,
            clearPendingDiscussionId: true,
            navigationRequestVersion: state.navigationRequestVersion + 1,
          ),
        );
      }
      return;
    }

    if (wasAuthenticated) {
      await _unregisterCurrentTokenBestEffort(emit);
    }
  }

  Future<void> _onTokenRefreshed(
    NotificationTokenRefreshedEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final token = event.token.trim();
    if (token.isEmpty) {
      return;
    }

    emit(state.copyWith(currentFcmToken: token, errorMessage: ''));

    if (!state.isAuthenticated) {
      return;
    }

    await _registerTokenIfNeeded(token, emit);
  }

  Future<void> _onForegroundMessageReceived(
    NotificationForegroundMessageReceivedEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (kDebugMode) {
      debugPrint('FCM foreground event handled. data=${event.data}');
    }

    final notificationType = event.data['type']?.trim() ?? '';
    final notificationDiscussionId = _readDiscussionId(event.data);
    final syncType = _resolveSyncType(notificationType);

    var nextState = state.copyWith(
      lastNotificationType: notificationType,
      notificationDiscussionId: notificationDiscussionId,
      notificationEventVersion: state.notificationEventVersion + 1,
      errorMessage: '',
    );

    if (_shouldSyncActiveDiscussion(
      syncType: syncType,
      notificationDiscussionId: notificationDiscussionId,
      activeDiscussionId: state.activeDiscussionId,
    )) {
      if (kDebugMode) {
        switch (syncType) {
          case NotificationSyncType.messagesOnly:
            debugPrint(
              '[SILENT SYNC] MESSAGE_UPDATED discussionId=${notificationDiscussionId ?? '-'}',
            );
            break;
          case NotificationSyncType.contextOnly:
            debugPrint(
              '[SILENT SYNC] CONTEXT_CHANGED discussionId=${notificationDiscussionId ?? '-'}',
            );
            break;
          case NotificationSyncType.discussionAndMessages:
            debugPrint(
              '[FCM] active discussion matched - ${_timestampNow()} - '
              'discussionId=${notificationDiscussionId ?? '-'}',
            );
            break;
          case NotificationSyncType.none:
            break;
        }
      }

      if (kDebugMode) {
        if (notificationType == 'DISCUSSION_MESSAGE_DELETED') {
          debugPrint(
            '[SILENT SYNC] MESSAGE_DELETED discussionId=${notificationDiscussionId ?? '-'}',
          );
        }
      }

      nextState = nextState.copyWith(
        syncType: syncType,
        syncDiscussionId: notificationDiscussionId,
        syncVersion: state.syncVersion + 1,
      );
    }

    emit(nextState);
  }

  void _onActiveDiscussionChanged(
    NotificationActiveDiscussionChangedEvent event,
    Emitter<NotificationState> emit,
  ) {
    final normalizedDiscussionId = event.discussionId?.trim();
    if (normalizedDiscussionId == null || normalizedDiscussionId.isEmpty) {
      emit(state.copyWith(clearActiveDiscussionId: true));
      return;
    }

    if (state.activeDiscussionId == normalizedDiscussionId) {
      return;
    }

    emit(
      state.copyWith(
        activeDiscussionId: normalizedDiscussionId,
        errorMessage: '',
      ),
    );
  }

  void _onAppLifecycleResumed(
    NotificationAppLifecycleResumedEvent event,
    Emitter<NotificationState> emit,
  ) {
    final activeDiscussionId = state.activeDiscussionId?.trim();
    if (activeDiscussionId == null || activeDiscussionId.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        refreshDiscussionId: activeDiscussionId,
        refreshRequestVersion: state.refreshRequestVersion + 1,
        errorMessage: '',
      ),
    );
  }

  Future<void> _onNotificationOpened(
    NotificationOpenedEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (kDebugMode) {
      debugPrint(
        'FCM open event handled. source=${event.source}, data=${event.data}',
      );
    }

    final discussionId = _readDiscussionId(event.data);
    if (discussionId == null) {
      return;
    }

    if (state.isAuthenticated) {
      final activeDiscussionId = state.activeDiscussionId?.trim();
      if (activeDiscussionId != null && activeDiscussionId == discussionId) {
        emit(
          state.copyWith(
            refreshDiscussionId: discussionId,
            refreshRequestVersion: state.refreshRequestVersion + 1,
            errorMessage: '',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          openDiscussionId: discussionId,
          clearPendingDiscussionId: true,
          navigationRequestVersion: state.navigationRequestVersion + 1,
        ),
      );
      return;
    }

    emit(state.copyWith(pendingDiscussionId: discussionId));
  }

  Future<void> _onNavigationHandled(
    NotificationNavigationHandledEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(clearOpenDiscussionId: true));
  }

  Future<void> _ensurePermissionAndToken(
    Emitter<NotificationState> emit,
  ) async {
    if (!state.permissionRequested) {
      try {
        await _messagingDataSource.requestPermission();
        if (kDebugMode) {
          debugPrint('FCM PERMISSION requested on supported platform.');
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('FCM requestPermission failed: $error');
        }
      }

      emit(state.copyWith(permissionRequested: true));
    }

    final existingToken = state.currentFcmToken?.trim();
    if (existingToken != null && existingToken.isNotEmpty) {
      return;
    }

    try {
      final token = await _messagingDataSource.getToken();
      if (kDebugMode) {
        debugPrint('FCM TOKEN ACTUAL: $token');
      }

      final normalizedToken = token?.trim();
      if (normalizedToken != null && normalizedToken.isNotEmpty) {
        emit(state.copyWith(currentFcmToken: normalizedToken));
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('FCM getToken failed: $error');
      }
    }
  }

  Future<void> _registerTokenIfNeeded(
    String token,
    Emitter<NotificationState> emit,
  ) async {
    final currentRegistered = state.lastRegisteredToken?.trim();
    if (currentRegistered == token) {
      return;
    }

    final result = await _registerDevice(
      RegisterDeviceParams(
        token: token,
        platform: NotificationDevicePlatform.android,
      ),
    );

    if (result is Success<void>) {
      emit(state.copyWith(lastRegisteredToken: token, errorMessage: ''));
      return;
    }

    if (result is FailureResult<void>) {
      emit(state.copyWith(errorMessage: result.failure.message));
    }
  }

  Future<void> _unregisterCurrentTokenBestEffort(
    Emitter<NotificationState> emit,
  ) async {
    final token = (state.currentFcmToken ?? state.lastRegisteredToken)?.trim();
    if (token == null || token.isEmpty) {
      emit(state.copyWith(clearLastRegisteredToken: true));
      return;
    }

    final result = await _unregisterDevice(
      UnregisterDeviceParams(token: token),
    );
    if (result is FailureResult<void> && kDebugMode) {
      debugPrint(
        'FCM unregister failed during logout: ${result.failure.message}',
      );
    }

    emit(state.copyWith(clearLastRegisteredToken: true));
  }

  String? _readDiscussionId(Map<String, String> data) {
    final value = data['discussionId']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  NotificationSyncType _resolveSyncType(String notificationType) {
    switch (notificationType) {
      case 'DISCUSSION_MESSAGE':
        return NotificationSyncType.discussionAndMessages;
      case 'DISCUSSION_MESSAGE_UPDATED':
      case 'DISCUSSION_MESSAGE_DELETED':
        return NotificationSyncType.messagesOnly;
      case 'DISCUSSION_CONTEXT_CHANGED':
        return NotificationSyncType.contextOnly;
      default:
        return NotificationSyncType.none;
    }
  }

  bool _shouldSyncActiveDiscussion({
    required NotificationSyncType syncType,
    required String? notificationDiscussionId,
    required String? activeDiscussionId,
  }) {
    if (syncType == NotificationSyncType.none) {
      return false;
    }

    final incomingDiscussionId = notificationDiscussionId?.trim();
    final currentActiveDiscussionId = activeDiscussionId?.trim();

    if (incomingDiscussionId == null ||
        incomingDiscussionId.isEmpty ||
        currentActiveDiscussionId == null ||
        currentActiveDiscussionId.isEmpty) {
      return false;
    }

    return incomingDiscussionId == currentActiveDiscussionId;
  }

  String _timestampNow() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    return '$hh:$mm:$ss.$ms';
  }

  @override
  Future<void> close() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
    return super.close();
  }
}
