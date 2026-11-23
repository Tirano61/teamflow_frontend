import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../data/datasources/firebase_messaging_data_source.dart';
import '../../domain/entities/push_notification.dart';
import '../../domain/repositories/notification_device_repository.dart';
import '../../domain/usecases/reconcile_device_token.dart';
import '../../domain/usecases/register_device.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({
    required FirebaseMessagingDataSource messagingDataSource,
    required RegisterDevice registerDevice,
    required ReconcileDeviceToken reconcileDeviceToken,
  }) : _messagingDataSource = messagingDataSource,
       _registerDevice = registerDevice,
       _reconcileDeviceToken = reconcileDeviceToken,
       super(const NotificationState()) {
    on<InitializeNotificationsEvent>(_onInitializeNotifications);
    on<NotificationAuthStateChangedEvent>(_onAuthStateChanged);
    on<NotificationTokenRefreshedEvent>(_onTokenRefreshed);
    on<NotificationForegroundMessageReceivedEvent>(
      _onForegroundMessageReceived,
    );
    on<NotificationOpenedEvent>(_onNotificationOpened);
    on<NotificationNavigationHandledEvent>(_onNavigationHandled);
    on<NotificationInfoMessageConsumedEvent>(_onInfoMessageConsumed);
    on<NotificationActiveDiscussionChangedEvent>(_onActiveDiscussionChanged);
    on<NotificationActiveDiscussionClearedEvent>(_onActiveDiscussionCleared);
    on<NotificationAppLifecycleResumedEvent>(_onAppLifecycleResumed);
  }

  final FirebaseMessagingDataSource _messagingDataSource;
  final RegisterDevice _registerDevice;
  final ReconcileDeviceToken _reconcileDeviceToken;

  /// Tope para reintentar la revocacion pendiente antes de registrar: sin red
  /// no debe demorar el registro (que igualmente reasigna el token).
  static const Duration _tokenReconcileTimeout = Duration(seconds: 5);

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<PushNotification>? _foregroundMessageSubscription;
  StreamSubscription<PushNotification>? _messageOpenedSubscription;

  /// Aviso cuando la notificacion pertenece a una organizacion en la que el
  /// usuario no tiene Membership `ACTIVE`. No nombra la organizacion ni la
  /// Discussion.
  static const String _organizationUnavailableMessage =
      'No tenes acceso a la organizacion de esta notificacion.';

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
      notification,
    ) {
      _debugLog(
        'onMessage received - ${_timestampNow()} - ${_describe(notification)}',
      );
      add(NotificationForegroundMessageReceivedEvent(notification));
    });

    _messageOpenedSubscription = _messagingDataSource.onMessageOpenedApp.listen(
      (notification) {
        add(
          NotificationOpenedEvent(
            notification: notification,
            source: 'onMessageOpenedApp',
          ),
        );
      },
    );

    try {
      final initialMessage = await _messagingDataSource.getInitialMessage();
      if (initialMessage != null) {
        add(
          NotificationOpenedEvent(
            notification: initialMessage,
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

    // La sesion restaurada pudo llegar mientras se inicializaba.
    await _registerCurrentDevice(emit);

    // Arranque sin sesion: un logout anterior pudo dejar la revocacion del
    // token pendiente.
    if (!state.isAuthenticated) {
      await _reconcileTokenRevocation(emit);
    }
  }

  Future<void> _onAuthStateChanged(
    NotificationAuthStateChangedEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final wasAuthenticated = state.isAuthenticated;
    final previousUserId = state.currentUserId;
    final isAuthenticated = event.isAuthenticated;
    final isSessionResolved = isAuthenticated && event.isSessionResolved;
    final currentUserId = isAuthenticated ? event.currentUserId.trim() : '';

    emit(
      state.copyWith(
        isAuthenticated: isAuthenticated,
        isSessionResolved: isSessionResolved,
        isWorkspaceReady: isSessionResolved && event.isWorkspaceReady,
        currentUserId: currentUserId,
        activeOrganizationId: isAuthenticated
            ? event.activeOrganizationId.trim()
            : '',
        organizationIds: isAuthenticated
            ? List<String>.unmodifiable(event.organizationIds)
            : const <String>[],
        errorMessage: '',
      ),
    );

    if (!isAuthenticated) {
      if (wasAuthenticated) {
        _clearUserScopedState(emit);
      }
      return;
    }

    // Otro usuario sin pasar por `unauthenticated`: nada del anterior sigue
    // vigente.
    if (previousUserId.isNotEmpty &&
        currentUserId.isNotEmpty &&
        previousUserId != currentUserId) {
      _clearUserScopedState(emit);
    }

    // Antes que el registro: pedir el permiso puede esperar al usuario.
    _resolvePendingNavigation(emit);

    if (!wasAuthenticated) {
      await _registerCurrentDevice(emit);
    }
  }

  /// Registra el token FCM del dispositivo para el usuario autenticado.
  ///
  /// Si la sesion llega antes de que termine la inicializacion, la propia
  /// inicializacion lo vuelve a intentar al terminar.
  Future<void> _registerCurrentDevice(Emitter<NotificationState> emit) async {
    if (!state.pushSupported || !state.initialized || !state.isAuthenticated) {
      return;
    }

    // Un logout sin conexion pudo dejar el token sin revocar: se revoca antes
    // de registrar, asi el nuevo usuario recibe un token que nunca estuvo
    // asociado al anterior. Si no hay red se registra el actual, que el
    // backend reasigna a este usuario.
    await _reconcileTokenRevocation(emit);

    await _ensurePermissionAndToken(emit);
    final token = state.currentFcmToken?.trim();
    if (token != null && token.isNotEmpty) {
      await _registerTokenIfNeeded(token, emit);
    }
  }

  /// Avanza la notificacion tocada pendiente lo que permita la sesion actual.
  ///
  /// Cada paso espera al anterior y se reevalua con cada cambio de sesion:
  /// 1. sesion resuelta: JWT valido, `/me/context` cargado y splash terminado;
  /// 2. destinatario: `recipientUserId` debe ser el usuario de `/me/context`;
  ///    si no lo es se descarta sin aviso (no se revela nada de otra cuenta);
  /// 3. organizacion: debe estar entre las organizaciones `ACTIVE` del
  ///    usuario; si no, se descarta con un aviso generico;
  /// 4. si no es la organizacion activa, se pide el cambio (lo aplica la app
  ///    con `AuthOrganizationSelected`) y se espera el contexto nuevo;
  /// 5. con el Workspace listo en esa organizacion, se abre la Discussion.
  ///
  /// Los ids del push solo eligen la pantalla: el acceso real lo validan las
  /// rutas tenant del backend al abrir la Discussion.
  void _resolvePendingNavigation(Emitter<NotificationState> emit) {
    final pending = state.pendingNotification;
    if (pending == null) {
      return;
    }

    if (!state.isAuthenticated || !state.isSessionResolved) {
      return;
    }

    final currentUserId = state.currentUserId;
    if (currentUserId.isEmpty || pending.recipientUserId != currentUserId) {
      _debugLog('open discarded: recipient is not the current user');
      emit(
        state.copyWith(
          clearPendingNotification: true,
          clearOrganizationSwitchRequest: true,
        ),
      );
      return;
    }

    final organizationId = pending.organizationId!;
    if (!state.organizationIds.contains(organizationId)) {
      _debugLog('open discarded: organization not available for the user');
      emit(
        state.copyWith(
          clearPendingNotification: true,
          clearOrganizationSwitchRequest: true,
          infoMessage: _organizationUnavailableMessage,
          infoMessageVersion: state.infoMessageVersion + 1,
        ),
      );
      return;
    }

    if (state.activeOrganizationId != organizationId) {
      if (state.organizationSwitchRequestId == organizationId) {
        // Cambio ya pedido: se espera al contexto nuevo.
        return;
      }

      _debugLog('open requires switching the active organization');
      emit(
        state.copyWith(
          organizationSwitchRequestId: organizationId,
          organizationSwitchRequestVersion:
              state.organizationSwitchRequestVersion + 1,
        ),
      );
      return;
    }

    if (!state.isWorkspaceReady) {
      return;
    }

    final discussionId = pending.discussionId!;
    if (state.activeDiscussionId == discussionId) {
      emit(
        state.copyWith(
          clearPendingNotification: true,
          clearOrganizationSwitchRequest: true,
          refreshDiscussionId: discussionId,
          refreshRequestVersion: state.refreshRequestVersion + 1,
          errorMessage: '',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        clearPendingNotification: true,
        clearOrganizationSwitchRequest: true,
        openDiscussionId: discussionId,
        navigationRequestVersion: state.navigationRequestVersion + 1,
      ),
    );
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
    final notification = event.notification;

    // Solo eventos de Discussions de la sesion y la organizacion activas: un
    // push de otro usuario (token todavia asociado a la cuenta anterior) o de
    // otra organizacion no refresca nada de la pantalla actual.
    if (!_isForActiveWorkspace(notification)) {
      _debugLog('foreground message ignored: ${_describe(notification)}');

      // Un push sin sesion prueba que hay conexion y que el token sigue
      // asociado a una cuenta: momento para reintentar la revocacion.
      if (!state.isAuthenticated) {
        await _reconcileTokenRevocation(emit);
      }
      return;
    }

    final notificationType = notification.type;
    final notificationDiscussionId = notification.discussionId;
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

  void _onActiveDiscussionCleared(
    NotificationActiveDiscussionClearedEvent event,
    Emitter<NotificationState> emit,
  ) {
    if (state.activeDiscussionId != event.discussionId.trim()) {
      return;
    }

    emit(state.copyWith(clearActiveDiscussionId: true));
  }

  Future<void> _onAppLifecycleResumed(
    NotificationAppLifecycleResumedEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (!state.isAuthenticated) {
      await _reconcileTokenRevocation(emit);
      return;
    }

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
    final notification = event.notification;
    _debugLog('open (${event.source}): ${_describe(notification)}');

    // `TEST` y tipos desconocidos no representan una Discussion; un evento de
    // Discussion sin destinatario, organizacion o Discussion validos tampoco
    // se puede abrir de forma segura.
    if (!notification.targetsDiscussion) {
      return;
    }

    // La misma Discussion ya espera abrirse o se acaba de pedir (toques
    // repetidos o notificaciones duplicadas).
    final pending = state.pendingNotification;
    if (state.openDiscussionId == notification.discussionId ||
        (pending != null &&
            pending.discussionId == notification.discussionId &&
            pending.recipientUserId == notification.recipientUserId)) {
      return;
    }

    // La ultima notificacion tocada manda: reemplaza la pendiente y su pedido
    // de cambio de organizacion.
    emit(
      state.copyWith(
        pendingNotification: notification,
        clearOrganizationSwitchRequest: true,
      ),
    );
    _resolvePendingNavigation(emit);
  }

  /// La app ya empujo el detalle: queda como discussion activa enseguida, sin
  /// esperar a que la pantalla se construya, para que un toque repetido sobre
  /// la misma notificacion refresque en lugar de abrir un segundo detalle.
  Future<void> _onNavigationHandled(
    NotificationNavigationHandledEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final openedDiscussionId = state.openDiscussionId;
    emit(
      state.copyWith(
        clearOpenDiscussionId: true,
        activeDiscussionId: openedDiscussionId,
      ),
    );
  }

  void _onInfoMessageConsumed(
    NotificationInfoMessageConsumedEvent event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(infoMessage: ''));
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
      final normalizedToken = token?.trim();
      // Solo se registra si hay token: el valor permite enviar pushes al
      // dispositivo y no debe aparecer en logs.
      _debugLog(
        'getToken completed: '
        'hasToken=${normalizedToken != null && normalizedToken.isNotEmpty}',
      );

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

    // Pedir el permiso o el token puede tardar: si la sesion se cerro en el
    // medio, registrar ya no corresponde (y sin JWT fallaria).
    if (!state.isAuthenticated) {
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

  /// Reintenta la revocacion pendiente del token FCM (ver `AuthBloc`). Si se
  /// revoco, el token conocido ya no sirve: el proximo registro pide uno
  /// nuevo a Firebase.
  Future<void> _reconcileTokenRevocation(
    Emitter<NotificationState> emit,
  ) async {
    if (!state.pushSupported || !state.initialized) {
      return;
    }

    try {
      final revoked = await _reconcileDeviceToken().timeout(
        _tokenReconcileTimeout,
      );
      if (!revoked) {
        return;
      }

      _debugLog('pending token revocation completed');
      emit(
        state.copyWith(
          clearCurrentFcmToken: true,
          clearLastRegisteredToken: true,
        ),
      );
    } on TimeoutException {
      _debugLog('pending token revocation timed out');
    }
  }

  /// Cierre de sesion (logout o sesion expirada) o cambio de usuario.
  ///
  /// El desregistro del token en el backend ya lo hizo `AuthBloc` antes de
  /// borrar el JWT: aca no se hace ninguna request (sin JWT terminaria en
  /// "Sesion no iniciada"). Solo se descarta lo que pertenece al usuario
  /// anterior, incluida una notificacion tocada que esperaba abrirse. El
  /// permiso es del dispositivo y se conserva; el token cacheado se descarta
  /// porque el logout pudo revocarlo, y el proximo registro lo vuelve a leer
  /// de Firebase.
  void _clearUserScopedState(Emitter<NotificationState> emit) {
    emit(
      state.copyWith(
        clearCurrentFcmToken: true,
        clearLastRegisteredToken: true,
        clearPendingNotification: true,
        clearOrganizationSwitchRequest: true,
        clearOpenDiscussionId: true,
        clearActiveDiscussionId: true,
        clearNotificationDiscussionId: true,
        clearSyncDiscussionId: true,
        clearRefreshDiscussionId: true,
        syncType: NotificationSyncType.none,
        lastNotificationType: '',
        infoMessage: '',
        errorMessage: '',
      ),
    );
  }

  /// Evento de Discussion para el usuario de la sesion y de la organizacion
  /// activa, con el Workspace listo.
  bool _isForActiveWorkspace(PushNotification notification) {
    if (!notification.targetsDiscussion || !state.isWorkspaceReady) {
      return false;
    }

    return notification.recipientUserId == state.currentUserId &&
        notification.organizationId == state.activeOrganizationId;
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

  /// Descripcion para logs de depuracion: tipo, Discussion y que campos
  /// llegaron, sin ids de usuario ni de organizacion.
  String _describe(PushNotification notification) {
    final type = notification.type.isEmpty ? '-' : notification.type;
    return 'type=$type '
        'discussionId=${notification.discussionId ?? '-'} '
        'hasRecipient=${notification.recipientUserId != null} '
        'hasOrganization=${notification.organizationId != null}';
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[FCM] $message');
    }
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
