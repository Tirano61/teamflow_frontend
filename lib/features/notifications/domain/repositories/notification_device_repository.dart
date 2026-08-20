import '../../../../core/error/result.dart';

enum NotificationDevicePlatform { android }

extension NotificationDevicePlatformApi on NotificationDevicePlatform {
  String get apiValue {
    switch (this) {
      case NotificationDevicePlatform.android:
        return 'ANDROID';
    }
  }
}

abstract class NotificationDeviceRepository {
  Future<Result<void>> registerDevice({
    required String token,
    required NotificationDevicePlatform platform,
  });

  Future<Result<void>> unregisterDevice({required String token});
}
