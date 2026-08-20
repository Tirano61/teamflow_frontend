import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/applications/presentation/bloc/application_bloc.dart';
import '../../features/applications/presentation/pages/applications_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/branding/presentation/pages/branding_splash_page.dart';
import '../../features/discussions/domain/entities/discussion.dart';
import '../../features/discussions/presentation/bloc/discussion_bloc.dart';
import '../../features/discussions/presentation/pages/discussion_detail_page.dart';
import '../../features/discussions/presentation/pages/discussion_editor_page.dart';
import '../../features/discussions/presentation/pages/discussion_route_args.dart';
import '../../features/discussions/presentation/pages/discussions_page.dart';
import '../../features/discussion_messages/presentation/bloc/discussion_message_bloc.dart';
import '../../features/indicators/presentation/bloc/indicator_bloc.dart';
import '../../features/indicators/presentation/pages/indicators_page.dart';
import '../../features/share_intent/presentation/pages/share_intent_compose_page.dart';
import '../../features/share_intent/presentation/pages/share_intent_route_args.dart';
import '../../features/tags/presentation/bloc/tag_bloc.dart';
import '../../features/tags/presentation/pages/tags_page.dart';
import '../di/service_locator.dart';
import '../network/auth_token_provider.dart';
import '../widgets/integration_menu_page.dart';
import '../widgets/app_placeholder_page.dart';

class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String applications = '/applications';
  static const String indicators = '/indicators';
  static const String tags = '/tags';
  static const String discussions = '/discussions';
  static const String discussionDetail = '/discussions/detail';
  static const String discussionCreate = '/discussions/create';
  static const String shareIntentCompose = '/share-intent/compose';
}

class AppRouter {
  const AppRouter._();

  static final ValueNotifier<bool> isBrandingSplashActive = ValueNotifier<bool>(
    false,
  );

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static final RouteObserver<ModalRoute<dynamic>> routeObserver =
      RouteObserver<ModalRoute<dynamic>>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const BrandingSplashPage(),
        );
      case AppRoutes.login:
        return _buildLoginRoute(settings);
      case AppRoutes.applications:
        return _buildProtectedRoute(
          settings: settings,
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<ApplicationBloc>(create: (_) => sl<ApplicationBloc>()),
              BlocProvider<IndicatorBloc>(create: (_) => sl<IndicatorBloc>()),
              BlocProvider<TagBloc>(create: (_) => sl<TagBloc>()),
            ],
            child: const ApplicationsPage(),
          ),
        );
      case AppRoutes.indicators:
        return _buildProtectedRoute(
          settings: settings,
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<ApplicationBloc>(create: (_) => sl<ApplicationBloc>()),
              BlocProvider<IndicatorBloc>(create: (_) => sl<IndicatorBloc>()),
              BlocProvider<TagBloc>(create: (_) => sl<TagBloc>()),
            ],
            child: const IndicatorsPage(),
          ),
        );
      case AppRoutes.tags:
        return _buildProtectedRoute(
          settings: settings,
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<ApplicationBloc>(create: (_) => sl<ApplicationBloc>()),
              BlocProvider<IndicatorBloc>(create: (_) => sl<IndicatorBloc>()),
              BlocProvider<TagBloc>(create: (_) => sl<TagBloc>()),
            ],
            child: const TagsPage(),
          ),
        );
      case AppRoutes.discussions:
        return _buildProtectedRoute(
          settings: settings,
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<DiscussionBloc>(create: (_) => sl<DiscussionBloc>()),
              BlocProvider<DiscussionMessageBloc>(
                create: (_) => sl<DiscussionMessageBloc>(),
              ),
              BlocProvider<ApplicationBloc>(
                create: (_) => sl<ApplicationBloc>(),
              ),
              BlocProvider<IndicatorBloc>(create: (_) => sl<IndicatorBloc>()),
              BlocProvider<TagBloc>(create: (_) => sl<TagBloc>()),
            ],
            child: const DiscussionsPage(),
          ),
        );
      case AppRoutes.discussionDetail:
        final discussionId = _readDiscussionId(settings.arguments);
        if (discussionId == null || discussionId.isEmpty) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const AppPlaceholderPage(
              title: 'Discussion Detail',
              description:
                  'Falta un discussionId valido para abrir la pantalla de detalle.',
            ),
          );
        }

        return _buildProtectedRoute(
          settings: settings,
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<DiscussionBloc>(create: (_) => sl<DiscussionBloc>()),
              BlocProvider<DiscussionMessageBloc>(
                create: (_) => sl<DiscussionMessageBloc>(),
              ),
              BlocProvider<ApplicationBloc>(create: (_) => sl<ApplicationBloc>()),
              BlocProvider<IndicatorBloc>(create: (_) => sl<IndicatorBloc>()),
              BlocProvider<TagBloc>(create: (_) => sl<TagBloc>()),
            ],
            child: DiscussionDetailPage(discussionId: discussionId),
          ),
        );
      case AppRoutes.discussionCreate:
        final editorArgs = _readEditorArgs(settings.arguments);
        return _buildProtectedRoute(
          settings: settings,
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<DiscussionBloc>(create: (_) => sl<DiscussionBloc>()),
              BlocProvider<DiscussionMessageBloc>(
                create: (_) => sl<DiscussionMessageBloc>(),
              ),
              BlocProvider<ApplicationBloc>(
                create: (_) => sl<ApplicationBloc>(),
              ),
              BlocProvider<IndicatorBloc>(create: (_) => sl<IndicatorBloc>()),
              BlocProvider<TagBloc>(create: (_) => sl<TagBloc>()),
            ],
            child: DiscussionEditorPage(
              initialDiscussion: editorArgs.discussion,
              discussionId: editorArgs.discussionId,
            ),
          ),
        );
      case AppRoutes.shareIntentCompose:
        final args = _readShareIntentArgs(settings.arguments);
        return _buildProtectedRoute(
          settings: settings,
          builder: (_) => ShareIntentComposePage(routeArgs: args),
        );
      case AppRoutes.home:
        return _buildProtectedRoute(
          settings: settings,
          builder: (_) => const IntegrationMenuPage(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AppPlaceholderPage(
            title: 'Develop Workflow',
            description: 'Ruta no encontrada en la configuracion de AppRouter.',
          ),
        );
    }
  }

  static Route<dynamic> _buildLoginRoute(RouteSettings settings) {
    if (_hasAuthenticatedSession()) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const IntegrationMenuPage(),
      );
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const LoginPage(),
    );
  }

  static Route<dynamic> _buildProtectedRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    if (!_hasAuthenticatedSession()) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LoginPage(),
      );
    }

    return MaterialPageRoute<void>(settings: settings, builder: builder);
  }

  static bool _hasAuthenticatedSession() {
    if (!sl.isRegistered<AuthTokenProvider>()) {
      return false;
    }

    return sl<AuthTokenProvider>().hasAccessToken;
  }

  static String? _readDiscussionId(Object? args) {
    if (args is DiscussionDetailRouteArgs) {
      return args.discussionId;
    }

    if (args is String) {
      return args;
    }

    return null;
  }

  static DiscussionEditorRouteArgs _readEditorArgs(Object? args) {
    if (args is DiscussionEditorRouteArgs) {
      return args;
    }

    if (args is Discussion) {
      return DiscussionEditorRouteArgs(discussion: args, discussionId: args.id);
    }

    if (args is String) {
      return DiscussionEditorRouteArgs(discussionId: args);
    }

    return const DiscussionEditorRouteArgs();
  }

  static ShareIntentComposeRouteArgs _readShareIntentArgs(Object? args) {
    if (args is ShareIntentComposeRouteArgs) {
      return args;
    }

    return const ShareIntentComposeRouteArgs();
  }
}
