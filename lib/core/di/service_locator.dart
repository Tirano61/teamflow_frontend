import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../../features/work_modules/data/datasources/work_module_remote_data_source.dart';
import '../../features/work_modules/data/repositories/work_module_repository_impl.dart';
import '../../features/work_modules/domain/repositories/work_module_repository.dart';
import '../../features/work_modules/domain/usecases/create_work_module.dart';
import '../../features/work_modules/domain/usecases/get_work_module_components.dart';
import '../../features/work_modules/domain/usecases/get_work_module.dart';
import '../../features/work_modules/domain/usecases/get_work_modules.dart';
import '../../features/work_modules/domain/usecases/associate_component_to_work_module.dart';
import '../../features/work_modules/domain/usecases/remove_component_from_work_module.dart';
import '../../features/work_modules/domain/usecases/set_work_module_active.dart';
import '../../features/work_modules/domain/usecases/update_work_module.dart';
import '../../features/work_modules/presentation/bloc/work_module_bloc.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/restore_session_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/discussions/data/datasources/discussion_remote_data_source.dart';
import '../../features/discussions/data/repositories/discussion_repository_impl.dart';
import '../../features/discussions/domain/repositories/discussion_repository.dart';
import '../../features/discussions/domain/usecases/add_discussion_assignments.dart';
import '../../features/discussions/domain/usecases/create_discussion.dart';
import '../../features/discussions/domain/usecases/get_assignable_developers.dart';
import '../../features/discussions/domain/usecases/get_discussion.dart';
import '../../features/discussions/domain/usecases/get_discussions.dart';
import '../../features/discussions/domain/usecases/mark_discussion_as_read.dart';
import '../../features/discussions/domain/usecases/remove_discussion_assignment.dart';
import '../../features/discussions/domain/usecases/replace_discussion_assignments.dart';
import '../../features/discussions/domain/usecases/update_discussion.dart';
import '../../features/discussions/domain/usecases/update_discussion_status.dart';
import '../../features/discussions/presentation/bloc/discussion_bloc.dart';
import '../../features/discussion_messages/data/datasources/discussion_message_remote_data_source.dart';
import '../../features/discussion_messages/data/repositories/discussion_message_repository_impl.dart';
import '../../features/discussion_messages/domain/repositories/discussion_message_repository.dart';
import '../../features/discussion_messages/domain/usecases/create_discussion_message.dart';
import '../../features/discussion_messages/domain/usecases/delete_discussion_message.dart';
import '../../features/discussion_messages/domain/usecases/get_discussion_messages.dart';
import '../../features/discussion_messages/domain/usecases/upload_discussion_message_attachment.dart';
import '../../features/discussion_messages/domain/usecases/update_discussion_message.dart';
import '../../features/discussion_messages/presentation/bloc/discussion_message_bloc.dart';
import '../../features/components/data/datasources/component_remote_data_source.dart';
import '../../features/components/data/repositories/component_repository_impl.dart';
import '../../features/components/domain/repositories/component_repository.dart';
import '../../features/components/domain/usecases/create_component.dart';
import '../../features/components/domain/usecases/get_component_work_modules.dart';
import '../../features/components/domain/usecases/get_component.dart';
import '../../features/components/domain/usecases/get_components.dart';
import '../../features/components/domain/usecases/set_component_active.dart';
import '../../features/components/domain/usecases/update_component.dart';
import '../../features/components/presentation/bloc/component_bloc.dart';
import '../../features/notifications/data/datasources/firebase_messaging_data_source.dart';
import '../../features/notifications/data/datasources/notification_device_remote_data_source.dart';
import '../../features/notifications/data/repositories/notification_device_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_device_repository.dart';
import '../../features/notifications/domain/usecases/register_device.dart';
import '../../features/notifications/domain/usecases/unregister_device.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/share_intent/data/datasources/share_intent_data_source.dart';
import '../../features/share_intent/presentation/bloc/share_intent_bloc.dart';
import '../../features/tags/data/datasources/tag_remote_data_source.dart';
import '../../features/tags/data/repositories/tag_repository_impl.dart';
import '../../features/tags/domain/repositories/tag_repository.dart';
import '../../features/tags/domain/usecases/create_tag.dart';
import '../../features/tags/domain/usecases/get_tags.dart';
import '../../features/tags/domain/usecases/set_tag_active.dart';
import '../../features/tags/domain/usecases/update_tag.dart';
import '../../features/tags/presentation/bloc/tag_bloc.dart';
import '../network/auth_token_provider.dart';
import '../network/http_rest_client.dart';
import '../organization/organization_context.dart';
import '../network/network_config.dart';
import '../network/rest_client.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (!sl.isRegistered<NetworkConfig>()) {
    sl.registerLazySingleton<NetworkConfig>(NetworkConfig.fromEnvironment);
  }

  if (!sl.isRegistered<OrganizationContext>()) {
    sl.registerLazySingleton<OrganizationContext>(OrganizationContext.new);
  }

  if (!sl.isRegistered<http.Client>()) {
    sl.registerLazySingleton<http.Client>(http.Client.new);
  }

  if (!sl.isRegistered<SharedPreferences>()) {
    final preferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => preferences);
  }

  if (!sl.isRegistered<AuthLocalDataSource>()) {
    final localDataSource = AuthLocalDataSourceImpl(
      sharedPreferences: sl<SharedPreferences>(),
    );
    await localDataSource.initialize();
    sl.registerLazySingleton<AuthLocalDataSource>(() => localDataSource);
  }

  if (!sl.isRegistered<AuthTokenProvider>()) {
    sl.registerLazySingleton<AuthTokenProvider>(
      () => sl<AuthLocalDataSource>() as AuthTokenProvider,
    );
  }

  if (!sl.isRegistered<RestClient>()) {
    sl.registerLazySingleton<RestClient>(
      () => HttpRestClient(
        client: sl<http.Client>(),
        config: sl<NetworkConfig>(),
        authTokenProvider: sl<AuthTokenProvider>(),
      ),
    );
  }

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(restClient: sl<RestClient>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
    ),
  );
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<RestoreSessionUseCase>(
    () => RestoreSessionUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(sl<AuthRepository>()),
  );
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      restoreSessionUseCase: sl<RestoreSessionUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      authTokenProvider: sl<AuthTokenProvider>(),
    ),
  );

  sl.registerLazySingleton<FirebaseMessagingDataSource>(() {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      return FirebaseMessagingDataSourceImpl();
    }

    return const FirebaseMessagingNoOpDataSource();
  });
  sl.registerLazySingleton<NotificationDeviceRemoteDataSource>(
    () => NotificationDeviceRemoteDataSourceImpl(restClient: sl<RestClient>()),
  );
  sl.registerLazySingleton<NotificationDeviceRepository>(
    () => NotificationDeviceRepositoryImpl(
      remoteDataSource: sl<NotificationDeviceRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<RegisterDevice>(
    () => RegisterDevice(sl<NotificationDeviceRepository>()),
  );
  sl.registerLazySingleton<UnregisterDevice>(
    () => UnregisterDevice(sl<NotificationDeviceRepository>()),
  );
  sl.registerFactory<NotificationBloc>(
    () => NotificationBloc(
      messagingDataSource: sl<FirebaseMessagingDataSource>(),
      registerDevice: sl<RegisterDevice>(),
      unregisterDevice: sl<UnregisterDevice>(),
    ),
  );

  sl.registerLazySingleton<WorkModuleRemoteDataSource>(
    () => WorkModuleRemoteDataSourceImpl(restClient: sl<RestClient>()),
  );
  sl.registerLazySingleton<WorkModuleRepository>(
    () => WorkModuleRepositoryImpl(
      remoteDataSource: sl<WorkModuleRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetWorkModules>(
    () => GetWorkModules(sl<WorkModuleRepository>()),
  );
  sl.registerLazySingleton<GetWorkModule>(
    () => GetWorkModule(sl<WorkModuleRepository>()),
  );
  sl.registerLazySingleton<CreateWorkModule>(
    () => CreateWorkModule(sl<WorkModuleRepository>()),
  );
  sl.registerLazySingleton<UpdateWorkModule>(
    () => UpdateWorkModule(sl<WorkModuleRepository>()),
  );
  sl.registerLazySingleton<SetWorkModuleActive>(
    () => SetWorkModuleActive(sl<WorkModuleRepository>()),
  );
  sl.registerLazySingleton<GetWorkModuleComponents>(
    () => GetWorkModuleComponents(sl<WorkModuleRepository>()),
  );
  sl.registerLazySingleton<AssociateComponentToWorkModule>(
    () => AssociateComponentToWorkModule(sl<WorkModuleRepository>()),
  );
  sl.registerLazySingleton<RemoveComponentFromWorkModule>(
    () => RemoveComponentFromWorkModule(sl<WorkModuleRepository>()),
  );
  sl.registerFactory<WorkModuleBloc>(
    () => WorkModuleBloc(
      getApplications: sl<GetWorkModules>(),
      getApplication: sl<GetWorkModule>(),
      createApplication: sl<CreateWorkModule>(),
      updateApplication: sl<UpdateWorkModule>(),
      setApplicationActive: sl<SetWorkModuleActive>(),
      getApplicationIndicators: sl<GetWorkModuleComponents>(),
      associateIndicator: sl<AssociateComponentToWorkModule>(),
      removeAssociatedIndicator: sl<RemoveComponentFromWorkModule>(),
    ),
  );

  sl.registerLazySingleton<ComponentRemoteDataSource>(
    () => ComponentRemoteDataSourceImpl(restClient: sl<RestClient>()),
  );
  sl.registerLazySingleton<ComponentRepository>(
    () => ComponentRepositoryImpl(
      remoteDataSource: sl<ComponentRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetComponents>(
    () => GetComponents(sl<ComponentRepository>()),
  );
  sl.registerLazySingleton<GetComponent>(
    () => GetComponent(sl<ComponentRepository>()),
  );
  sl.registerLazySingleton<CreateComponent>(
    () => CreateComponent(sl<ComponentRepository>()),
  );
  sl.registerLazySingleton<UpdateComponent>(
    () => UpdateComponent(sl<ComponentRepository>()),
  );
  sl.registerLazySingleton<SetComponentActive>(
    () => SetComponentActive(sl<ComponentRepository>()),
  );
  sl.registerLazySingleton<GetComponentWorkModules>(
    () => GetComponentWorkModules(sl<ComponentRepository>()),
  );
  sl.registerFactory<ComponentBloc>(
    () => ComponentBloc(
      getIndicators: sl<GetComponents>(),
      getIndicator: sl<GetComponent>(),
      createIndicator: sl<CreateComponent>(),
      updateIndicator: sl<UpdateComponent>(),
      setIndicatorActive: sl<SetComponentActive>(),
      getIndicatorApplications: sl<GetComponentWorkModules>(),
    ),
  );

  sl.registerLazySingleton<TagRemoteDataSource>(
    () => TagRemoteDataSourceImpl(restClient: sl<RestClient>()),
  );
  sl.registerLazySingleton<TagRepository>(
    () => TagRepositoryImpl(remoteDataSource: sl<TagRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetTags>(() => GetTags(sl<TagRepository>()));
  sl.registerLazySingleton<CreateTag>(() => CreateTag(sl<TagRepository>()));
  sl.registerLazySingleton<UpdateTag>(() => UpdateTag(sl<TagRepository>()));
  sl.registerLazySingleton<SetTagActive>(
    () => SetTagActive(sl<TagRepository>()),
  );
  sl.registerFactory<TagBloc>(
    () => TagBloc(
      getTags: sl<GetTags>(),
      createTag: sl<CreateTag>(),
      updateTag: sl<UpdateTag>(),
      setTagActive: sl<SetTagActive>(),
    ),
  );

  sl.registerLazySingleton<DiscussionRemoteDataSource>(
    () => DiscussionRemoteDataSourceImpl(restClient: sl<RestClient>()),
  );
  sl.registerLazySingleton<DiscussionRepository>(
    () => DiscussionRepositoryImpl(
      remoteDataSource: sl<DiscussionRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetDiscussions>(
    () => GetDiscussions(sl<DiscussionRepository>()),
  );
  sl.registerLazySingleton<GetDiscussion>(
    () => GetDiscussion(sl<DiscussionRepository>()),
  );
  sl.registerLazySingleton<MarkDiscussionAsRead>(
    () => MarkDiscussionAsRead(sl<DiscussionRepository>()),
  );
  sl.registerLazySingleton<CreateDiscussion>(
    () => CreateDiscussion(sl<DiscussionRepository>()),
  );
  sl.registerLazySingleton<UpdateDiscussion>(
    () => UpdateDiscussion(sl<DiscussionRepository>()),
  );
  sl.registerLazySingleton<UpdateDiscussionStatus>(
    () => UpdateDiscussionStatus(sl<DiscussionRepository>()),
  );
  sl.registerLazySingleton<GetAssignableDevelopers>(
    () => GetAssignableDevelopers(sl<DiscussionRepository>()),
  );
  sl.registerLazySingleton<AddDiscussionAssignments>(
    () => AddDiscussionAssignments(sl<DiscussionRepository>()),
  );
  sl.registerLazySingleton<ReplaceDiscussionAssignments>(
    () => ReplaceDiscussionAssignments(sl<DiscussionRepository>()),
  );
  sl.registerLazySingleton<RemoveDiscussionAssignment>(
    () => RemoveDiscussionAssignment(sl<DiscussionRepository>()),
  );
  sl.registerFactory<DiscussionBloc>(
    () => DiscussionBloc(
      getDiscussions: sl<GetDiscussions>(),
      getDiscussion: sl<GetDiscussion>(),
      markDiscussionAsRead: sl<MarkDiscussionAsRead>(),
      createDiscussion: sl<CreateDiscussion>(),
      updateDiscussion: sl<UpdateDiscussion>(),
      updateDiscussionStatus: sl<UpdateDiscussionStatus>(),
      getAssignableDevelopers: sl<GetAssignableDevelopers>(),
      addDiscussionAssignments: sl<AddDiscussionAssignments>(),
      replaceDiscussionAssignments: sl<ReplaceDiscussionAssignments>(),
      removeDiscussionAssignment: sl<RemoveDiscussionAssignment>(),
    ),
  );

  sl.registerLazySingleton<DiscussionMessageRemoteDataSource>(
    () => DiscussionMessageRemoteDataSourceImpl(restClient: sl<RestClient>()),
  );
  sl.registerLazySingleton<DiscussionMessageRepository>(
    () => DiscussionMessageRepositoryImpl(
      remoteDataSource: sl<DiscussionMessageRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetDiscussionMessages>(
    () => GetDiscussionMessages(sl<DiscussionMessageRepository>()),
  );
  sl.registerLazySingleton<CreateDiscussionMessage>(
    () => CreateDiscussionMessage(sl<DiscussionMessageRepository>()),
  );
  sl.registerLazySingleton<UploadDiscussionMessageAttachment>(
    () => UploadDiscussionMessageAttachment(sl<DiscussionMessageRepository>()),
  );
  sl.registerLazySingleton<UpdateDiscussionMessage>(
    () => UpdateDiscussionMessage(sl<DiscussionMessageRepository>()),
  );
  sl.registerLazySingleton<DeleteDiscussionMessage>(
    () => DeleteDiscussionMessage(sl<DiscussionMessageRepository>()),
  );
  sl.registerFactory<DiscussionMessageBloc>(
    () => DiscussionMessageBloc(
      getDiscussionMessages: sl<GetDiscussionMessages>(),
      createDiscussionMessage: sl<CreateDiscussionMessage>(),
      uploadDiscussionMessageAttachment:
          sl<UploadDiscussionMessageAttachment>(),
      updateDiscussionMessage: sl<UpdateDiscussionMessage>(),
      deleteDiscussionMessage: sl<DeleteDiscussionMessage>(),
    ),
  );

  sl.registerLazySingleton<ShareIntentDataSource>(
    () => ShareIntentDataSourceImpl(),
  );
  sl.registerFactory<ShareIntentBloc>(
    () => ShareIntentBloc(
      shareIntentDataSource: sl<ShareIntentDataSource>(),
      getDiscussions: sl<GetDiscussions>(),
      uploadAttachment: sl<UploadDiscussionMessageAttachment>(),
    ),
  );
}



