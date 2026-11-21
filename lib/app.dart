import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/navigation/post_auth_destination.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/discussions/presentation/pages/discussion_route_args.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/presentation/bloc/notification_event.dart';
import 'features/notifications/presentation/bloc/notification_state.dart';
import 'features/share_intent/presentation/bloc/share_intent_bloc.dart';
import 'features/share_intent/presentation/bloc/share_intent_event.dart';
import 'features/share_intent/presentation/bloc/share_intent_state.dart';
import 'features/share_intent/presentation/pages/share_intent_route_args.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AuthBloc _authBloc;
  late final NotificationBloc _notificationBloc;
  late final ShareIntentBloc _shareIntentBloc;
  bool _appWasInBackground = false;
  bool _shareComposerOpen = false;

  /// Ultimo contexto de sesion enviado a NotificationBloc y ShareIntentBloc
  /// (coincide con el estado inicial de ambos). Solo se envia un evento cuando
  /// cambia, para no repetir registros ni aperturas del composer.
  bool _sentAuthenticated = false;
  bool _sentWorkspaceReady = false;
  String _sentOrganizationId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authBloc = sl<AuthBloc>();
    _notificationBloc = sl<NotificationBloc>();
    _shareIntentBloc = sl<ShareIntentBloc>();
    _notificationBloc.add(const InitializeNotificationsEvent());
    _shareIntentBloc.add(const InitializeShareIntentEvent());
    AppRouter.isBrandingSplashActive.addListener(_onBrandingSplashChanged);
  }

  @override
  void dispose() {
    AppRouter.isBrandingSplashActive.removeListener(_onBrandingSplashChanged);
    WidgetsBinding.instance.removeObserver(this);
    _shareIntentBloc.close();
    _notificationBloc.close();
    _authBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _appWasInBackground = true;
        break;
      case AppLifecycleState.resumed:
        if (_appWasInBackground) {
          _appWasInBackground = false;
          _notificationBloc.add(const NotificationAppLifecycleResumedEvent());
        }
        break;
    }
  }

  /// Mientras el splash de marca esta activo los listeners de auth no
  /// navegan: la sesion guardada se restaura de fondo. Al terminar se aplica
  /// el estado de auth que haya en ese momento, en lugar de ir siempre al
  /// login.
  void _onBrandingSplashChanged() {
    if (AppRouter.isBrandingSplashActive.value) {
      return;
    }

    // Fuera del frame: el splash puede estar desmontandose y el Navigator no
    // admite navegar durante ese cambio.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final state = _authBloc.state;

      // `home` resuelve con AuthGatePage cualquier estado autenticado o aun
      // pendiente (espera, Workspace, seleccion, sin organizacion o error).
      // Se quita toda la pila, incluida la ruta `/` que el Navigator genera
      // debajo de `/splash`.
      AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        state.status == AuthStatus.unauthenticated
            ? AppRoutes.login
            : AppRoutes.home,
        (route) => false,
      );

      // Despues de navegar: lo que abran notificaciones o share-intent queda
      // encima de `home`, no debajo del reinicio de pila.
      _syncSessionDependents();
    });
  }

  /// Propaga el contexto de sesion a NotificationBloc y ShareIntentBloc.
  ///
  /// Es independiente de la navegacion: corre tambien durante el splash, asi
  /// una sesion restaurada en el arranque en frio registra el token FCM sin
  /// esperar a que termine la animacion.
  ///
  /// - autenticado: sesion valida (registro del token FCM, global).
  /// - Workspace listo: ademas organizacion activa validada contra
  ///   `/me/context` (la misma regla de [PostAuthDestinationResolver]) y el
  ///   splash ya termino. Solo entonces se abren discussions de notificaciones
  ///   o el composer de contenido compartido.
  ///
  /// El cambio de organizacion activa tambien se propaga a share-intent para
  /// que descarte las discussions de la organizacion anterior.
  void _syncSessionDependents() {
    final state = _authBloc.state;
    final isAuthenticated = state.isAuthenticated;
    final isWorkspaceReady =
        isAuthenticated &&
        !AppRouter.isBrandingSplashActive.value &&
        PostAuthDestinationResolver.resolve(state) ==
            PostAuthDestination.workspace;
    final organizationId = isWorkspaceReady ? state.activeOrganizationId : '';

    final sessionChanged =
        isAuthenticated != _sentAuthenticated ||
        isWorkspaceReady != _sentWorkspaceReady;
    final organizationChanged = organizationId != _sentOrganizationId;
    if (!sessionChanged && !organizationChanged) {
      return;
    }

    _sentAuthenticated = isAuthenticated;
    _sentWorkspaceReady = isWorkspaceReady;
    _sentOrganizationId = organizationId;

    if (sessionChanged) {
      _notificationBloc.add(
        NotificationAuthStateChangedEvent(
          isAuthenticated: isAuthenticated,
          isWorkspaceReady: isWorkspaceReady,
        ),
      );
    }

    _shareIntentBloc.add(
      ShareIntentAuthStatusChangedEvent(
        isAuthenticated: isAuthenticated,
        isWorkspaceReady: isWorkspaceReady,
      ),
    );
  }

  /// La sesion guardada se valido en el arranque (`checking` ->
  /// `authenticated`), a diferencia de un login explicito.
  static bool _isSessionRestored(AuthState previous, AuthState current) {
    return previous.status == AuthStatus.checking &&
        current.status == AuthStatus.authenticated;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<NotificationBloc>.value(value: _notificationBloc),
        BlocProvider<ShareIntentBloc>.value(value: _shareIntentBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                !_isSessionRestored(previous, current) &&
                (previous.status != current.status ||
                    previous.infoMessage != current.infoMessage),
            listener: (context, state) {
              if (AppRouter.isBrandingSplashActive.value) {
                return;
              }

              final navigator = AppRouter.navigatorKey.currentState;
              final messenger = AppRouter.scaffoldMessengerKey.currentState;

              if (state.infoMessage.isNotEmpty) {
                messenger
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.infoMessage)));
              }

              if (state.status == AuthStatus.authenticated) {
                navigator?.pushNamedAndRemoveUntil(
                  AppRoutes.home,
                  (route) => false,
                );
                return;
              }

              if (state.status == AuthStatus.unauthenticated) {
                navigator?.pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
          ),
          // Sesion guardada restaurada en el arranque.
          //
          // Si la pila se reconstruyo desde la URL (recarga de Flutter Web
          // sobre una ruta del Workspace) y la organizacion activa quedo
          // resuelta, se conserva: sus rutas esperaban en
          // `SessionRestoreGate` y ahora se construyen contra esa
          // organizacion. En cualquier otro caso (seleccion, sin
          // organizacion, error de contexto, o la pila del login) se reinicia
          // sobre `home`, igual que tras un login.
          BlocListener<AuthBloc, AuthState>(
            listenWhen: _isSessionRestored,
            listener: (context, state) {
              if (AppRouter.isBrandingSplashActive.value) {
                return;
              }

              final keepStack =
                  PostAuthDestinationResolver.resolve(state) ==
                      PostAuthDestination.workspace &&
                  AppRouter.canKeepRestoredStack();
              if (keepStack) {
                return;
              }

              AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
                AppRoutes.home,
                (route) => false,
              );
            },
          ),
          // Punto unico donde se reacciona a un cambio de organizacion activa
          // hecho desde el Workspace (el login lo cubre el listener de arriba,
          // que ya reinicia la pila al autenticar).
          //
          // Reiniciar la pila sobre `home` es lo que limpia el estado tenant:
          // los blocs de Discussions, DiscussionMessages, WorkModules,
          // Components y Tags son factories con alcance de ruta
          // (`AppRouter.onGenerateRoute`), asi que al descartar las rutas se
          // cierran y se vuelven a crear vacios contra el nuevo tenant. De paso
          // se cierra el selector y no queda abierta ninguna Discussion de la
          // organizacion anterior.
          //
          // Tambien cubre perder la organizacion activa sin que otra la
          // reemplace (id vacio tras recargar `/me/context`, por ejemplo al
          // abandonarla quedando 0 o varias organizaciones): `home` vuelve a
          // resolver el destino con `AuthGatePage` (sin organizacion,
          // seleccion o error de contexto) y no queda ninguna pantalla tenant
          // de la organizacion anterior.
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status == AuthStatus.authenticated &&
                current.status == AuthStatus.authenticated &&
                previous.activeOrganizationId.isNotEmpty &&
                previous.activeOrganizationId != current.activeOrganizationId,
            listener: (context, state) {
              AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
                AppRoutes.home,
                (route) => false,
              );
            },
          ),
          // Contexto de sesion para notificaciones y share-intent. Va despues
          // de los listeners de navegacion: si un mismo cambio reinicia la pila,
          // lo que abran estos blocs queda encima de la pila nueva.
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) => _syncSessionDependents(),
          ),
          BlocListener<NotificationBloc, NotificationState>(
            listenWhen: (previous, current) =>
                previous.navigationRequestVersion !=
                current.navigationRequestVersion,
            listener: (context, state) {
              final discussionId = state.openDiscussionId?.trim();
              if (discussionId == null || discussionId.isEmpty) {
                return;
              }

              final navigator = AppRouter.navigatorKey.currentState;
              navigator?.pushNamed(
                AppRoutes.discussionDetailLocation(discussionId),
                arguments: DiscussionDetailRouteArgs(
                  discussionId: discussionId,
                ),
              );

              context.read<NotificationBloc>().add(
                const NotificationNavigationHandledEvent(),
              );
            },
          ),
          BlocListener<ShareIntentBloc, ShareIntentState>(
            listenWhen: (previous, current) =>
                previous.composerRequestVersion !=
                    current.composerRequestVersion ||
                previous.infoMessageVersion != current.infoMessageVersion,
            listener: (context, state) async {
              final messenger = AppRouter.scaffoldMessengerKey.currentState;

              if (state.infoMessage.trim().isNotEmpty) {
                messenger
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.infoMessage)));
                context.read<ShareIntentBloc>().add(
                  const ShareIntentMessageConsumedEvent(),
                );
              }

              if (!state.isWorkspaceReady ||
                  state.pendingContent == null ||
                  _shareComposerOpen) {
                return;
              }

              _shareComposerOpen = true;
              final navigator = AppRouter.navigatorKey.currentState;
              final preferredDiscussionId = context
                  .read<NotificationBloc>()
                  .state
                  .activeDiscussionId;

              final result = await navigator?.pushNamed(
                AppRoutes.shareIntentCompose,
                arguments: ShareIntentComposeRouteArgs(
                  preferredDiscussionId: preferredDiscussionId,
                ),
              );

              _shareComposerOpen = false;

              final selectedDiscussionId = result is String
                  ? result.trim()
                  : '';
              if (selectedDiscussionId.isEmpty) {
                return;
              }

              navigator?.pushNamed(
                AppRoutes.discussionDetailLocation(selectedDiscussionId),
                arguments: DiscussionDetailRouteArgs(
                  discussionId: selectedDiscussionId,
                ),
              );
            },
          ),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          navigatorKey: AppRouter.navigatorKey,
          scaffoldMessengerKey: AppRouter.scaffoldMessengerKey,
          navigatorObservers: [AppRouter.routeObserver],
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
